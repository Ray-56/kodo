#!/usr/bin/env python3
"""Audit runtime HTTP logs only, without printing matched data."""
import re
from pathlib import Path
root=Path(__file__).resolve().parents[1]
logs=[root/'qa/evidence/m3-server.log',root/'qa/evidence/m6-restore-process.log']
for p in logs:
 text=p.read_text()
 for pattern in [r'Bearer\s+[0-9a-f-]{36}\.',r'"secret"\s*:',r'"payload"\s*:',r'"amount"\s*:',r'"name"\s*:']:
  assert not re.search(pattern,text),f'Potential private material in {p.name}; inspect locally'
print(f'PASS {len(logs)} runtime logs: no bearer credentials, registration secrets, or activity JSON bodies')
