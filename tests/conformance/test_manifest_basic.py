import json
import unittest
from pathlib import Path

REQUIRED = {"name", "version", "module", "class"}


class TestManifestBasic(unittest.TestCase):
    def test_manifest_has_required_fields(self):
        # Look for manifests in ./plugins/**/manifest.json if any
        base = Path("plugins")
        if not base.exists():
            self.skipTest("no plugins directory present")
        found = False
        for mf in base.rglob("manifest.json"):
            found = True
            data = json.loads(mf.read_text(encoding="utf-8"))
            missing = REQUIRED - set(data.keys())
            self.assertFalse(missing, f"Missing fields {missing} in {mf}")
        if not found:
            self.skipTest("no manifests found under plugins/")


if __name__ == "__main__":
    unittest.main()

