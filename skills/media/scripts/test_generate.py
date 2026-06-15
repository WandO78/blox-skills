import sys, pathlib, importlib.util
HERE = pathlib.Path(__file__).parent
spec = importlib.util.spec_from_file_location("gen", HERE / "generate.py")
gen = importlib.util.module_from_spec(spec); spec.loader.exec_module(gen)

def test_registry_loads_six_tasks():
    reg = gen.load_registry()
    assert len(reg["tasks"]) == 6

def test_resolve_defaults_to_task_default_tier():
    fal_id, entry = gen.resolve("text_to_image", None)
    assert entry["tier"] == "balanced" and fal_id == "fal-ai/nano-banana-pro"

def test_resolve_explicit_tier():
    fal_id, entry = gen.resolve("text_to_image", "budget")
    assert fal_id == "fal-ai/flux/schnell"

def test_cost_per_image_known_price():
    entry = gen.resolve("text_to_image", "budget")[1]
    q = gen.estimate_cost(entry, count=4, duration=None)
    assert q["known"] is True and abs(q["usd"] - 0.012) < 1e-9

def test_cost_per_second_known_price():
    entry = gen.resolve("upscale_video", "balanced")[1]
    q = gen.estimate_cost(entry, count=1, duration=10)
    assert q["known"] is True and abs(q["usd"] - 0.20) < 1e-9

def test_cost_null_price_is_unknown():
    entry = gen.resolve("image_to_video", "balanced")[1]
    q = gen.estimate_cost(entry, count=1, duration=5)
    assert q["known"] is False

def test_deep_get():
    assert gen.deep_get({"images":[{"url":"x"}]}, "images[0].url") == "x"
