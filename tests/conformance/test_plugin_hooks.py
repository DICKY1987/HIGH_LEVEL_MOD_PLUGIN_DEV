import unittest

from fwgp.plugins.base import BasePlugin


class Dummy(BasePlugin):
    pass


class TestPluginHooks(unittest.TestCase):
    def test_base_plugin_hooks_exist(self):
        d = Dummy()
        # All hooks callable without raising
        d.onFileDetected(type("E", (), {"path":"p","change_type":"created","ts":0,"repo":"r"})(), {})
        d.beforeStage(type("R", (), {"paths":[],"repo":"r","ctx":{}})(), {})
        d.afterStage(type("R", (), {"paths":[],"repo":"r","ctx":{}})(), {})
        d.beforeCommit(type("C", (), {"staged_summary":[],"repo":"r","author":None})(), {})
        d.afterCommit(None, {})
        d.beforePush(type("P", (), {"remote":"origin","branch":"main"})(), {})
        d.afterPush(type("P", (), {"remote":"origin","branch":"main"})(), {})
        d.beforePull(type("PL", (), {"remote":"origin","branch":"main"})(), {})
        d.afterPull(type("PR", (), {"updated":False,"conflicts":None})(), {})
        d.onConflict(type("CF", (), {"files":[]})(), {})


if __name__ == "__main__":
    unittest.main()

