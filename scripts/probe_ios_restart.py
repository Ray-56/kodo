#!/usr/bin/env python3
"""Same installed integration binary, force-stop/relaunch BEFORE Flutter drive uninstalls it."""
import json,sqlite3,subprocess,sys,time
from pathlib import Path
root=Path(__file__).resolve().parents[1]
device=sys.argv[1]
bundle='dev.example.kodoApp'
def run(*args):return subprocess.check_output(['xcrun','simctl',*args],text=True).strip()
container=run('get_app_container',device,bundle,'data')
run('terminate',device,bundle)
run('launch',device,bundle)
time.sleep(4)
files=list(Path(container).rglob('kodo.sqlite'))
assert len(files)==1
with sqlite3.connect(files[0]) as c:
 row=c.execute('select count(*),coalesce(sum(amount),0) from entries where voided_at_utc_ms is null').fetchone()
 pending=c.execute('select count(*) from outbox').fetchone()[0]
 assert row==(1,10),row
 assert pending==2,pending
run('io',device,'screenshot',str(root/'qa/evidence/m1-same-install-restart.png'))
(root/'qa/evidence/m1-same-install-database.json').write_text(json.dumps({'same_installation':True,'entry_count':row[0],'amount':row[1],'pending':pending,'force_stop_relaunch':True},indent=2)+'\n')
print('PASS same-installation force-stop/relaunch: 1 entry, 10 total, 2 pending operations')
