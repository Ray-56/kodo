#!/usr/bin/env python3
import json,sys
from pathlib import Path
import jsonschema
root=Path(__file__).resolve().parents[1]
p=Path(sys.argv[1]) if len(sys.argv)>1 else root/'qa/evidence/local-export.json'
jsonschema.Draft202012Validator(json.loads((root/'contracts/local_export.schema.json').read_text()),format_checker=jsonschema.FormatChecker()).validate(json.loads(p.read_text()))
print('PASS local export schema (strict fields, original dates, void markers, no credentials/outbox)')
