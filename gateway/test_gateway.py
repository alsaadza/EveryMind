import random
import unittest

import server


class ScrubTests(unittest.TestCase):
    def test_email_phone_ssn(self):
        t, n = server.scrub("Mail me at kid@example.com or call 555-123-4567, ssn 123-45-6789")
        self.assertNotIn("example.com", t)
        self.assertNotIn("4567", t)
        self.assertIn("[REDACTED-EMAIL]", t)
        self.assertIn("[REDACTED-PHONE]", t)
        self.assertIn("[REDACTED-SSN]", t)
        self.assertEqual(n, 3)

    def test_name_and_address(self):
        t, n = server.scrub("Hi, my name is Jordan Lee and I live at 42 Maple Street.")
        self.assertNotIn("Jordan", t)
        self.assertNotIn("Maple", t)
        self.assertEqual(n, 2)

    def test_no_false_positive(self):
        t, n = server.scrub("I'm confused about why P(A) = 1/6 when rolling a die.")
        self.assertEqual(n, 0)
        self.assertIn("1/6", t)

    def test_url_with_query(self):
        t, n = server.scrub("see https://school.example/report?student=991")
        self.assertIn("[REDACTED-URL]", t)
        self.assertEqual(n, 1)


class AggregateTests(unittest.TestCase):
    def test_suppression_and_noise(self):
        evs = [{"kind": "misconception", "tag": "gambler", "value": 0.2}] * 12
        evs += [{"kind": "misconception", "tag": "rare", "value": 1.0}] * 3
        items = server.aggregate(evs, k=5, epsilon=1.0, rng=random.Random(1))
        by = {i["tag"]: i for i in items}
        self.assertTrue(by["rare"]["suppressed"])
        self.assertIsNone(by["rare"]["count"])
        self.assertFalse(by["gambler"]["suppressed"])
        self.assertAlmostEqual(by["gambler"]["mean_value"], 0.2)
        self.assertTrue(4 <= by["gambler"]["count"] <= 20)

    def test_validate_event_rejects_ids(self):
        self.assertIsNotNone(server.validate_event({"kind": "a", "tag": "b", "student_id": "x"}))
        self.assertIsNone(server.validate_event({"kind": "a", "tag": "b", "topic": "t",
                                                 "chapter_index": 1, "value": 0.5}))



class MockStructureTests(unittest.TestCase):
    def test_structure_plan_is_indices_only(self):
        import json
        backend = server.MockBackend("mock")
        content = "Preferred chunk size: about 2 sentences.\n0: First.\n1: Second.\n2: Third."
        out = json.loads(backend.chat("sys", [{"role": "user", "content": content}], 100, 0.1, True, "structure"))
        flat = [i for c in out["chunks"] for i in c]
        self.assertEqual(sorted(flat), [0, 1, 2])
        self.assertNotIn("First", json.dumps(out))

if __name__ == "__main__":
    unittest.main()
