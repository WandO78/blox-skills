#!/usr/bin/env python3
import json, sys, pathlib
HERE = pathlib.Path(__file__).parent
REQUIRED_ENTRY = {"fal_id", "tier", "best_for", "output_path", "unit"}
VALID_TIERS = {"budget", "balanced", "premium"}

def main():
    data = json.loads((HERE / "models.json").read_text())
    errors = []
    if "tasks" not in data:
        errors.append("top-level 'tasks' missing")
    for task, spec in data.get("tasks", {}).items():
        if "default" not in spec or "tiers" not in spec:
            errors.append(f"{task}: needs 'default' and 'tiers'"); continue
        if spec["default"] not in spec["tiers"]:
            errors.append(f"{task}: default '{spec['default']}' not in tiers")
        for name, entry in spec["tiers"].items():
            if name not in VALID_TIERS:
                errors.append(f"{task}/{name}: tier name not in {VALID_TIERS}")
            missing = REQUIRED_ENTRY - entry.keys()
            if missing:
                errors.append(f"{task}/{name}: missing {missing}")
    if errors:
        print("REGISTRY INVALID:"); [print("  -", e) for e in errors]; sys.exit(1)
    print(f"REGISTRY OK: {len(data['tasks'])} tasks"); sys.exit(0)

if __name__ == "__main__":
    main()
