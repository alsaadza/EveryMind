#!/usr/bin/env python3
"""Margin privacy gateway (EducateAI).

A thin, auditable proxy between the iPad app and OCI Generative AI.
- Holds OCI credentials server-side (never on the learner's device).
- Scrubs personally identifiable information before any prompt leaves the gateway.
- Accepts de-identified learning signals and serves k-anonymous, differentially
  private aggregates for educator dashboards.

Stdlib only, plus the optional `oci` SDK. Run with --mock to skip OCI entirely.
"""
import argparse
import json
import math
import os
import random
import re
import sys
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlparse, parse_qs

HERE = os.path.dirname(os.path.abspath(__file__))
DATA_DIR = os.path.join(HERE, "data")
SIGNALS_FILE = os.path.join(DATA_DIR, "signals.jsonl")

DEFAULT_ENDPOINT = "https://inference.generativeai.us-chicago-1.oci.oraclecloud.com"
DEFAULT_MODEL = "meta.llama-3.3-70b-instruct"

# --------------------------------------------------------------------------- PII scrubbing

_PII_PATTERNS = [
    ("URL", re.compile(r"https?://[^\s]+\?[^\s]+", re.I)),
    ("EMAIL", re.compile(r"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}")),
    ("SSN", re.compile(r"\b\d{3}-\d{2}-\d{4}\b")),
    ("PHONE", re.compile(r"(?<!\w)(?:\+?\d{1,2}[\s.-]?)?(?:\(\d{3}\)|\d{3})[\s.-]?\d{3}[\s.-]?\d{4}(?!\w)")),
    ("ADDRESS", re.compile(
        r"\b\d{1,5}\s+(?:[A-Z][a-z]+\s){1,3}(?:Street|St|Avenue|Ave|Road|Rd|Boulevard|Blvd|Lane|Ln|Drive|Dr|Court|Ct|Way|Place|Pl)\b\.?")),
]


def scrub(text):
    """Return (scrubbed_text, redaction_count)."""
    if not isinstance(text, str):
        return text, 0
    count = 0
    for label, pattern in _PII_PATTERNS:
        text, n = pattern.subn(f"[REDACTED-{label}]", text)
        count += n

    def _name(m):
        return f"{m.group(1)} [REDACTED-NAME]"

    # Case-insensitive lead-in, but the name itself must be capitalised to avoid
    # redacting "I'm confused".
    text, n = re.subn(
        r"\b((?i:my name is|i am called|call me|i'm|i am))\s+([A-Z][a-z]+(?:\s+[A-Z][a-z]+)?)",
        _name, text)
    count += n
    return text, count


# --------------------------------------------------------------------------- Aggregation

ALLOWED_EVENT_KEYS = {"topic", "chapter_index", "kind", "tag", "value"}
_signals_lock = threading.Lock()
_signals = []  # list of (cohort, event)


def validate_event(ev):
    if not isinstance(ev, dict):
        return "event must be an object"
    extra = set(ev.keys()) - ALLOWED_EVENT_KEYS
    if extra:
        return f"disallowed keys: {sorted(extra)}"
    for k in ("kind", "tag"):
        if not isinstance(ev.get(k), str) or not ev.get(k):
            return f"'{k}' must be a non-empty string"
    if "value" in ev and ev["value"] is not None and not isinstance(ev["value"], (int, float)):
        return "'value' must be a number"
    if "chapter_index" in ev and not isinstance(ev["chapter_index"], int):
        return "'chapter_index' must be an integer"
    return None


def laplace(scale, rng=random):
    u = rng.random() - 0.5
    return -scale * math.copysign(1.0, u) * math.log(1 - 2 * abs(u))


def aggregate(events, k=5, epsilon=1.0, rng=random):
    groups = {}
    for ev in events:
        key = (ev["kind"], ev["tag"])
        g = groups.setdefault(key, {"n": 0, "vals": []})
        g["n"] += 1
        if isinstance(ev.get("value"), (int, float)):
            g["vals"].append(float(ev["value"]))
    items = []
    for (kind, tag), g in sorted(groups.items()):
        if g["n"] < k:
            items.append({"kind": kind, "tag": tag, "count": None,
                          "mean_value": None, "suppressed": True})
            continue
        noisy = max(0, int(round(g["n"] + laplace(1.0 / epsilon, rng))))
        mean = round(sum(g["vals"]) / len(g["vals"]), 3) if g["vals"] else None
        items.append({"kind": kind, "tag": tag, "count": noisy,
                      "mean_value": mean, "suppressed": False})
    return items


def load_signals():
    if not os.path.exists(SIGNALS_FILE):
        return
    with open(SIGNALS_FILE) as f:
        for line in f:
            try:
                rec = json.loads(line)
                _signals.append((rec["cohort"], rec["event"]))
            except Exception:
                continue


# --------------------------------------------------------------------------- Model backends

class MockBackend:
    provider = "mock"

    def __init__(self, model):
        self.model = model

    def chat(self, system, messages, max_tokens, temperature, want_json, purpose):
        if purpose == "tutor":
            return ("Good question. Before I explain, what do you already notice about it? "
                    "Try listing every possible outcome first. What do you count?")
        if purpose == "structure":
            # Group numbered sentences in pairs; indices only, never text.
            content = messages[-1]["content"] if messages else ""
            idx = [int(m.group(1)) for m in re.finditer(r"^(\d+): ", content, re.M)]
            chunks = [idx[i:i + 2] for i in range(0, len(idx), 2)]
            return json.dumps({"chunks": chunks, "labels": [f"Part {i + 1}" for i in range(len(chunks))], "steps": []})
        return "MOCK"


class OCIBackend:
    provider = "oci-generative-ai"

    def __init__(self, model):
        import oci  # noqa: F401  (lazy import)
        from oci.generative_ai_inference import GenerativeAiInferenceClient
        self.oci = oci
        self.model = model
        cfg_file = os.path.expanduser(os.environ.get("OCI_CONFIG_FILE", "~/.oci/config"))
        profile = os.environ.get("OCI_PROFILE", "DEFAULT")
        self.config = oci.config.from_file(cfg_file, profile)
        self.compartment = os.environ.get("OCI_COMPARTMENT_ID") or self.config.get("tenancy")
        endpoint = os.environ.get("OCI_GENAI_ENDPOINT", DEFAULT_ENDPOINT)
        self.client = GenerativeAiInferenceClient(
            config=self.config, service_endpoint=endpoint,
            retry_strategy=oci.retry.NoneRetryStrategy(), timeout=(10, 240))

    def chat(self, system, messages, max_tokens, temperature, want_json, purpose):
        m = self.oci.generative_ai_inference.models
        if want_json:
            system = (system or "") + ("\n\nReturn ONLY valid JSON. No markdown fences, "
                                       "no commentary before or after the JSON.")
        serving = m.OnDemandServingMode(model_id=self.model)
        if self.model.startswith("cohere."):
            history = []
            for msg in messages[:-1]:
                if msg["role"] == "assistant":
                    history.append(m.CohereChatBotMessage(message=msg["content"]))
                else:
                    history.append(m.CohereUserMessage(message=msg["content"]))
            req = m.CohereChatRequest(
                message=messages[-1]["content"] if messages else "",
                chat_history=history or None,
                preamble_override=system or None,
                max_tokens=max_tokens, temperature=temperature, is_stream=False)
        else:
            oci_msgs = []
            if system:
                oci_msgs.append(m.SystemMessage(content=[m.TextContent(text=system)]))
            for msg in messages:
                cls = m.AssistantMessage if msg["role"] == "assistant" else m.UserMessage
                oci_msgs.append(cls(content=[m.TextContent(text=msg["content"])]))
            req = m.GenericChatRequest(
                api_format=m.BaseChatRequest.API_FORMAT_GENERIC,
                messages=oci_msgs, max_tokens=max_tokens,
                temperature=temperature, is_stream=False)
        details = m.ChatDetails(compartment_id=self.compartment,
                                serving_mode=serving, chat_request=req)
        resp = self.client.chat(details)
        return extract_text(resp.data)


def extract_text(data):
    """Pull text out of a ChatResult for both Cohere and Generic formats."""
    cr = getattr(data, "chat_response", data)
    text = getattr(cr, "text", None)  # Cohere
    if isinstance(text, str) and text:
        return text
    choices = getattr(cr, "choices", None) or []
    parts = []
    for ch in choices:
        msg = getattr(ch, "message", None)
        for c in (getattr(msg, "content", None) or []):
            t = getattr(c, "text", None)
            if t:
                parts.append(t)
        if parts:
            break
    if parts:
        return "".join(parts)
    raise RuntimeError("could not extract text from OCI response")


# --------------------------------------------------------------------------- HTTP

def log(event, **fields):
    rec = {"ts": time.strftime("%Y-%m-%dT%H:%M:%S"), "event": event, **fields}
    print(json.dumps(rec), flush=True)


class Handler(BaseHTTPRequestHandler):
    backend = None
    token = None
    server_version = "MarginGateway/1.0"

    def log_message(self, fmt, *args):  # silence default access log (may contain paths only)
        pass

    def _send(self, code, obj):
        body = json.dumps(obj).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self._cors()
        self.end_headers()
        self.wfile.write(body)

    def _cors(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Headers", "Authorization, Content-Type")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")

    def _body(self):
        n = int(self.headers.get("Content-Length") or 0)
        if n > 2_000_000:
            raise ValueError("request too large")
        raw = self.rfile.read(n) if n else b"{}"
        return json.loads(raw or b"{}")

    def _authorized(self):
        if not self.token:
            return True
        return self.headers.get("Authorization", "") == f"Bearer {self.token}"

    def do_OPTIONS(self):
        self.send_response(204)
        self._cors()
        self.end_headers()

    def do_GET(self):
        url = urlparse(self.path)
        if url.path == "/health":
            return self._send(200, {"ok": True, "mode": "mock" if self.backend.provider == "mock" else "oci",
                                    "model": self.backend.model})
        if url.path == "/v1/insights":
            if not self._authorized():
                return self._send(401, {"error": "unauthorized"})
            q = parse_qs(url.query)
            cohort = q.get("cohort", ["default"])[0]
            try:
                k = max(2, int(q.get("k", ["5"])[0]))
                eps = float(q.get("epsilon", ["1.0"])[0])
                if eps <= 0:
                    raise ValueError
            except ValueError:
                return self._send(400, {"error": "invalid k or epsilon"})
            with _signals_lock:
                evs = [e for c, e in _signals if c == cohort]
            items = aggregate(evs, k=k, epsilon=eps)
            log("insights", cohort_len=len(cohort), groups=len(items))
            return self._send(200, {
                "cohort": cohort, "k": k, "epsilon": eps, "items": items,
                "note": (f"Groups with fewer than {k} events are suppressed. Counts include "
                         f"Laplace noise (epsilon={eps}). No learner identifiers are stored.")})
        return self._send(404, {"error": "not found"})

    def do_POST(self):
        url = urlparse(self.path)
        if not self._authorized():
            return self._send(401, {"error": "unauthorized"})
        try:
            body = self._body()
        except Exception as e:
            return self._send(400, {"error": f"invalid JSON: {e}"})
        if url.path == "/v1/chat":
            return self._chat(body)
        if url.path == "/v1/signals":
            return self._signals(body)
        return self._send(404, {"error": "not found"})

    def _chat(self, body):
        msgs = body.get("messages")
        if not isinstance(msgs, list) or not msgs:
            return self._send(400, {"error": "'messages' must be a non-empty list"})
        purpose = str(body.get("purpose", "general"))[:40]
        redactions = 0
        system, n = scrub(str(body.get("system", "")))
        redactions += n
        clean = []
        for m in msgs:
            if not isinstance(m, dict) or m.get("role") not in ("user", "assistant"):
                return self._send(400, {"error": "each message needs role user|assistant"})
            content, n = scrub(str(m.get("content", "")))
            redactions += n
            clean.append({"role": m["role"], "content": content})
        max_tokens = int(body.get("max_tokens") or 1200)
        temperature = float(body.get("temperature") if body.get("temperature") is not None else 0.4)
        t0 = time.time()
        try:
            text = self.backend.chat(system, clean, max_tokens, temperature,
                                     bool(body.get("json")), purpose)
        except Exception as e:
            log("chat_error", purpose=purpose, error=type(e).__name__)
            return self._send(502, {"error": f"model call failed: {type(e).__name__}: {e}"})
        log("chat", purpose=purpose, messages=len(clean),
            input_chars=len(system) + sum(len(m["content"]) for m in clean),
            output_chars=len(text), redactions=redactions,
            ms=int((time.time() - t0) * 1000))
        return self._send(200, {"text": text, "model": self.backend.model,
                                "provider": self.backend.provider, "redactions": redactions})

    def _signals(self, body):
        cohort = body.get("cohort")
        events = body.get("events")
        if not isinstance(cohort, str) or not cohort or len(cohort) > 64:
            return self._send(400, {"error": "'cohort' must be a short string"})
        if not isinstance(events, list):
            return self._send(400, {"error": "'events' must be a list"})
        for ev in events:
            err = validate_event(ev)
            if err:
                return self._send(400, {"error": f"rejected event: {err}"})
        os.makedirs(DATA_DIR, exist_ok=True)
        with _signals_lock:
            with open(SIGNALS_FILE, "a") as f:
                for ev in events:
                    _signals.append((cohort, ev))
                    f.write(json.dumps({"cohort": cohort, "event": ev}) + "\n")
        log("signals", accepted=len(events))
        return self._send(200, {"accepted": len(events)})


def main():
    ap = argparse.ArgumentParser(description="Margin OCI privacy gateway")
    ap.add_argument("--mock", action="store_true", help="do not call OCI; return canned replies")
    args = ap.parse_args()
    model = os.environ.get("OCI_GENAI_MODEL_ID", DEFAULT_MODEL)
    backend = None
    if not args.mock:
        try:
            backend = OCIBackend(model)
        except Exception as e:
            print(f"[gateway] OCI unavailable ({type(e).__name__}: {e}); falling back to mock mode",
                  file=sys.stderr)
    if backend is None:
        backend = MockBackend(model)
    Handler.backend = backend
    Handler.token = os.environ.get("GATEWAY_TOKEN") or None
    load_signals()
    port = int(os.environ.get("PORT", "8787"))
    srv = ThreadingHTTPServer(("0.0.0.0", port), Handler)
    print(f"[gateway] listening on 0.0.0.0:{port} mode={backend.provider} model={model} "
          f"auth={'on' if Handler.token else 'off'}", flush=True)
    try:
        srv.serve_forever()
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    main()
