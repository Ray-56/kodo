#!/usr/bin/env python3
"""SQLite Online Backup API: consistent snapshot including committed WAL contents."""
import argparse,os,sqlite3
from pathlib import Path
p=argparse.ArgumentParser(description=__doc__)
p.add_argument('source',type=Path);p.add_argument('destination',type=Path)
a=p.parse_args()
if a.destination.exists():p.error('destination already exists; refusing to overwrite')
if not a.source.is_file():p.error('source does not exist')
a.destination.parent.mkdir(parents=True,exist_ok=True)
fd=os.open(a.destination,os.O_CREAT|os.O_EXCL|os.O_WRONLY,0o600);os.close(fd)
with sqlite3.connect(f'file:{a.source.resolve()}?mode=ro',uri=True) as source,sqlite3.connect(a.destination) as target:
 source.backup(target)
 assert target.execute('PRAGMA integrity_check').fetchone()==('ok',)
print('Consistent SQLite backup created; integrity_check=ok. Protect this file as personal activity data.')
