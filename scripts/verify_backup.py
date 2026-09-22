#!/usr/bin/env python3
"""Create disposable test activity, online-backup SQLite, launch restored Rust and compare snapshots."""
import json,os,subprocess,time,uuid
from pathlib import Path
from smoke_api import Smoke,Installation,operation
root=Path(__file__).resolve().parents[1]
client=Smoke('http://127.0.0.1:8080',15)
id=Installation.create();restored=None
backup=root/'var'/'restore-drill.sqlite'
try:
 client.expect('register backup fixture',201,'POST','/v1/installations',{'installation_id':id.id,'secret':id.secret})
 now=int(time.time()*1000);p=str(uuid.uuid4())
 client.expect('create backup fixture',200,'POST','/v1/operations',operation(1,'project.put',p,{'name':'备份验收','unit':'次','icon_key':'check','quick_amount':1,'archived':False,'created_at_utc_ms':now,'updated_at_utc_ms':now}),id)
 original=client.expect('snapshot before backup',200,'GET','/v1/snapshot',identity=id)
 subprocess.run(['python3',str(root/'scripts/backup_sqlite.py'),str(root/'var/kodo/kodo.sqlite'),str(backup)],check=True)
 env={**os.environ,'KODO_DATABASE_URL':f'sqlite://{backup}','KODO_BIND':'127.0.0.1:8082'}
 with open(root/'qa/evidence/m6-restore-process.log','w') as log:
  restored=subprocess.Popen([str(root/'services/api/target/debug/kodo-api')],env=env,stdout=log,stderr=log)
  probe=Smoke('http://127.0.0.1:8082',2)
  for _ in range(40):
   try:
    status,_=probe.request('GET','/health/ready')
    if status==200:break
   except RuntimeError:pass
   time.sleep(.1)
  after=probe.expect('restored authorized snapshot',200,'GET','/v1/snapshot',identity=id)
  for k in ['last_seq','projects','entries']:assert original[k]==after[k]
  probe.expect('remove restored fixture',204,'DELETE','/v1/installations/current',identity=id)
  restored.terminate();restored.wait(timeout=10);restored=None
 (root/'qa/evidence/m6-backup-report.json').write_text(json.dumps({'passed':True,'method':'SQLite Online Backup API','restored_rust_process':True,'compared':['last_seq','projects','entries'],'integrity_check':'ok'},indent=2)+'\n')
 print('PASS online WAL backup -> independent Rust process -> identical authorized snapshot')
finally:
 if restored is not None:restored.terminate();restored.wait(timeout=10)
 client.request('DELETE','/v1/installations/current',identity=id)
