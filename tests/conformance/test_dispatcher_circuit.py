import time
import unittest

from fwgp.dispatcher import Dispatcher
from fwgp.state import StateStore


class SlowPlugin:
    def onFileDetected(self, evt, ctx):
        time.sleep(5)


class DummyLogger:
    def info(self, *a, **k):
        pass
    def warning(self, *a, **k):
        pass
    def error(self, *a, **k):
        pass


class TestDispatcherCircuit(unittest.TestCase):
    def test_circuit_breaker_disables_after_three_failures(self):
        state = StateStore(".")
        # Use a fresh key unlikely to exist
        key = "tests.sample.SlowPlugin"
        state.reset(key)
        disp = Dispatcher(state, DummyLogger(), timeout_sec=0.1)
        disp.plugins = []
        class LP:
            def __init__(self, k, inst):
                self.key = k
                self.instance = inst
        disp.plugins.append(LP(key, SlowPlugin()))
        # Trigger three timeouts
        for _ in range(3):
            disp.on_file_detected(type("E", (), {"path":"p","change_type":"created","ts":0,"repo":"r"})(), {})
        self.assertTrue(state.is_disabled(key))


if __name__ == "__main__":
    unittest.main()
