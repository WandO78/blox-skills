"""blox:media — fal.ai generation driven by the tiered registry.

Offline (no FAL_KEY): `list`, `cost`.  Live (needs FAL_KEY): `run`.

  python generate.py list [--task TASK]
  python generate.py cost --task TASK [--tier budget|balanced|premium] [--count N] [--duration SECS]
  python generate.py run  --task TASK [--tier ...] --prompt "..." --title "slug"
                          [--input-image P ...] [--image P] [--input P]
                          [--count N] [--duration SECS] [--aspect-ratio R] [--resolution R]
                          [--folder DIR]
"""
from __future__ import annotations
import argparse, json, os, re, shutil, subprocess, sys, time, urllib.request
from pathlib import Path

SKILL_ROOT = Path(__file__).resolve().parent.parent
IMAGE_TASKS = {"text_to_image", "image_edit", "upscale_image"}
VIDEO_TASKS = {"image_to_video", "upscale_video"}
AUDIO_TASKS = {"tts"}

def load_registry() -> dict:
    return json.loads((SKILL_ROOT / "registry" / "models.json").read_text(encoding="utf-8"))

def load_config() -> dict:
    p = SKILL_ROOT / "config.json"
    return json.loads(p.read_text(encoding="utf-8")) if p.exists() else {"output_dir": "~/Documents/Blox Media"}

def resolve(task: str, tier: str | None):
    reg = load_registry()
    if task not in reg["tasks"]:
        raise SystemExit(f"unknown task '{task}'. Available: {list(reg['tasks'])}")
    spec = reg["tasks"][task]
    tier = tier or spec["default"]
    if tier not in spec["tiers"]:
        raise SystemExit(f"task '{task}' has no tier '{tier}'. Available: {list(spec['tiers'])}")
    return spec["tiers"][tier]["fal_id"], spec["tiers"][tier]

def estimate_cost(entry: dict, count: int = 1, duration: float | None = None) -> dict:
    price = entry.get("price_usd")
    unit = entry.get("unit")
    if price is None:
        return {"known": False, "unit": unit, "fal_id": entry["fal_id"]}
    if unit == "per_second":
        d = duration if duration is not None else (entry.get("default_args", {}).get("duration", 5))
        usd = price * d * count
    elif unit in ("per_image", "per_request"):
        usd = price * count
    else:
        usd = price * count
    return {"known": True, "usd": round(usd, 4), "unit": unit, "fal_id": entry["fal_id"]}

def slugify(text: str) -> str:
    s = re.sub(r"[^\w\s-]", "", text.lower()); s = re.sub(r"[-\s]+", "-", s).strip("-")
    return s[:50] or "untitled"

def expand_path(p: str) -> Path:
    return Path(os.path.expanduser(os.path.expandvars(p)))

def get_or_make_folder(output_dir: Path, title: str) -> Path:
    folder = output_dir / f"{time.strftime('%Y-%m-%d')}-{slugify(title)}"
    folder.mkdir(parents=True, exist_ok=True); return folder

def next_index(folder: Path, kind: str, ext: str) -> int:
    pat = re.compile(rf"^{kind}-(\d+)\.{ext}$")
    used = [int(m.group(1)) for f in folder.iterdir() if (m := pat.match(f.name))]
    return (max(used) + 1) if used else 1

def deep_get(obj, dotted: str):
    cur = obj
    for part in dotted.split("."):
        m = re.match(r"^(\w+)\[(\d+)\]$", part)
        cur = cur[m.group(1)][int(m.group(2))] if m else cur[part]
    return cur

def download(url: str, dest: Path) -> None:
    # Use the same TLS stack that worked for the API (httpx/certifi); honors
    # SSL_CERT_FILE / REQUESTS_CA_BUNDLE for corporate CA bundles. urllib fallback.
    try:
        import httpx
        verify = os.environ.get("SSL_CERT_FILE") or os.environ.get("REQUESTS_CA_BUNDLE") or True
        with httpx.stream("GET", url, verify=verify, follow_redirects=True, timeout=180) as r:
            r.raise_for_status()
            with open(dest, "wb") as f:
                for chunk in r.iter_bytes():
                    f.write(chunk)
    except ImportError:
        urllib.request.urlretrieve(url, dest)

def _require_key():
    if not os.environ.get("FAL_KEY"):
        raise SystemExit("FAL_KEY not set. export FAL_KEY=... in ~/.zshrc (get one at fal.ai/dashboard/keys)")

def _quote_line(task, tier_entry, count, duration):
    q = estimate_cost(tier_entry, count, duration)
    if q["known"]:
        return f"{q['fal_id']} ({task}): ~${q['usd']} ({q['unit']}, count={count}" + (f", {duration}s" if duration else "") + ")"
    return f"{q['fal_id']} ({task}): price not cached — verify live at https://fal.ai/models/{q['fal_id']} before quoting"

def cmd_list(args):
    reg = load_registry()
    tasks = [args.task] if args.task else list(reg["tasks"])
    for t in tasks:
        spec = reg["tasks"][t]
        print(f"\n{t}  (default: {spec['default']})")
        for name, e in spec["tiers"].items():
            price = f"${e['price_usd']}/{e['unit']}" if e.get("price_usd") is not None else f"{e['unit']} (verify live)"
            print(f"  - {name:9} {e['fal_id']:42} {price}  — {e['best_for']}")

def cmd_cost(args):
    _, entry = resolve(args.task, args.tier)
    print(_quote_line(args.task, entry, args.count, args.duration))

def cmd_run(args):
    _require_key()
    try:
        import fal_client
    except ImportError:
        raise SystemExit("fal_client not installed. pip install fal-client")
    fal_id, spec = resolve(args.task, args.tier)
    call = dict(spec.get("default_args", {}))
    if args.aspect_ratio: call["aspect_ratio"] = args.aspect_ratio
    if args.resolution: call["resolution"] = args.resolution
    if args.duration is not None: call["duration"] = args.duration

    out_dir = expand_path(load_config().get("output_dir", "~/Documents/Blox Media"))
    folder = expand_path(args.folder) if args.folder else get_or_make_folder(out_dir, args.title)
    folder.mkdir(parents=True, exist_ok=True)

    if args.task in AUDIO_TASKS:
        call["text"] = args.prompt; kind, ext = "audio", "mp3"
    elif args.task == "image_to_video":
        if not args.image: raise SystemExit("image_to_video needs --image (start frame)")
        call["image_url"] = fal_client.upload_file(str(expand_path(args.image)))
        call["prompt"] = args.prompt; kind, ext = "video", "mp4"
    elif args.task in ("upscale_image", "upscale_video"):
        if not args.input: raise SystemExit("upscale needs --input (source file)")
        src = fal_client.upload_file(str(expand_path(args.input)))
        call["video_url" if args.task == "upscale_video" else "image_url"] = src
        kind, ext = ("video", "mp4") if args.task == "upscale_video" else ("image", "png")
    else:
        call["prompt"] = args.prompt; kind, ext = "image", "png"
        if args.input_image:
            call["image_urls"] = [fal_client.upload_file(str(expand_path(p))) for p in args.input_image]

    sys.stderr.write(f"[blox:media] {args.task} via {fal_id} ...\n"); sys.stderr.flush()
    result = fal_client.subscribe(fal_id, arguments=call, with_logs=False)
    url = deep_get(result, spec["output_path"])
    idx = next_index(folder, kind, ext)
    out = folder / f"{kind}-{idx:02d}.{ext}"
    download(url, out)

    md = folder / "prompt.md"
    with md.open("a", encoding="utf-8") as f:
        f.write(f"\n## {args.task} ({fal_id})\n- file: {out.name}\n- prompt: {args.prompt}\n")
    print(json.dumps({"path": str(out), "folder": str(folder), "model": fal_id, "fal_url": url}))

def build_parser():
    p = argparse.ArgumentParser(prog="blox-media")
    sub = p.add_subparsers(dest="cmd", required=True)
    pl = sub.add_parser("list"); pl.add_argument("--task"); pl.set_defaults(func=cmd_list)
    pc = sub.add_parser("cost")
    pc.add_argument("--task", required=True); pc.add_argument("--tier"); pc.add_argument("--count", type=int, default=1)
    pc.add_argument("--duration", type=float, default=None); pc.set_defaults(func=cmd_cost)
    pr = sub.add_parser("run")
    pr.add_argument("--task", required=True); pr.add_argument("--tier")
    pr.add_argument("--prompt", default=""); pr.add_argument("--title", default="untitled")
    pr.add_argument("--input-image", dest="input_image", action="append")
    pr.add_argument("--image"); pr.add_argument("--input")
    pr.add_argument("--count", type=int, default=1); pr.add_argument("--duration", type=float, default=None)
    pr.add_argument("--aspect-ratio", dest="aspect_ratio"); pr.add_argument("--resolution")
    pr.add_argument("--folder"); pr.set_defaults(func=cmd_run)
    return p

if __name__ == "__main__":
    a = build_parser().parse_args(); a.func(a)
