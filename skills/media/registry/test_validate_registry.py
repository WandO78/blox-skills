import json, subprocess, sys, pathlib
HERE = pathlib.Path(__file__).parent

def test_registry_passes_validation():
    r = subprocess.run([sys.executable, str(HERE / "validate_registry.py")],
                       capture_output=True, text=True)
    assert r.returncode == 0, r.stdout + r.stderr

def test_every_task_has_a_default_in_its_tiers():
    data = json.loads((HERE / "models.json").read_text())
    for task, spec in data["tasks"].items():
        assert spec["default"] in spec["tiers"], f"{task}: default not among tiers"

def test_every_tier_entry_has_required_fields():
    data = json.loads((HERE / "models.json").read_text())
    req = {"fal_id", "tier", "best_for", "output_path"}
    for task, spec in data["tasks"].items():
        for name, entry in spec["tiers"].items():
            assert req <= entry.keys(), f"{task}/{name} missing {req - entry.keys()}"
