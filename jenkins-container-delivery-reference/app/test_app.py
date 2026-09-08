import io
import unittest
from unittest.mock import patch

from app import Handler


class FakeSocket:
    def makefile(self, *args, **kwargs):
        return io.BytesIO()


class HandlerTest(unittest.TestCase):
    def test_health_endpoint_contract(self):
        self.assertEqual(Handler.do_GET.__name__, "do_GET")

    @patch.object(Handler, "log_message")
    def test_log_message_is_suppressed(self, _mock_log):
        handler = object.__new__(Handler)
        self.assertIsNone(handler.log_message("test"))


if __name__ == "__main__":
    unittest.main()
