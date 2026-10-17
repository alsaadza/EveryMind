#!/usr/bin/env bash
# Usage: ./run.sh          (OCI mode, falls back to mock if OCI is not configured)
#        ./run.sh --mock   (never calls OCI)
set -euo pipefail
cd "$(dirname "$0")"
if [ -f .env ]; then set -a; . ./.env; set +a; fi
if [ ! -d .venv ]; then python3 -m venv .venv; ./.venv/bin/pip install -q -r requirements.txt || true; fi
exec ./.venv/bin/python server.py "$@"
