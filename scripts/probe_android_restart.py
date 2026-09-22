#!/usr/bin/env python3
"""Force-stop the same QA APK before flutter drive removes it. No reinstall/clear."""
import json, os, re, sqlite3, subprocess, sys, tempfile, time
from pathlib import Path
adb = os.environ.get('ANDROID_HOME', str(Path.home() / 'Library/Android/sdk')) + '/platform-tools/adb'
device, folder, mode = sys.argv[1:]
folder = Path(folder)
package = 'dev.example.kodo_app.qa'
activity = package + '/dev.example.kodo_app.MainActivity'
def run(*args):
    return subprocess.check_output([adb, '-s', device, *args], text=True).strip()
def snapshot():
    with tempfile.TemporaryDirectory() as td:
        for name in ['kodo.sqlite', 'kodo.sqlite-wal', 'kodo.sqlite-shm']:
            p = subprocess.run([adb, '-s', device, 'exec-out', 'run-as', package, 'cat', 'files/' + name], capture_output=True)
            if p.returncode == 0:
                Path(td, name).write_bytes(p.stdout)
            elif name == 'kodo.sqlite':
                raise RuntimeError('QA database unavailable')
        with sqlite3.connect(Path(td, 'kodo.sqlite')) as c:
            return {
                'projects': c.execute('select count(*) from projects').fetchone()[0],
                'entries': c.execute('select count(*) from entries where voided_at_utc_ms is null').fetchone()[0],
                'amount': c.execute('select coalesce(sum(amount),0) from entries where voided_at_utc_ms is null').fetchone()[0],
                'pending': c.execute('select count(*) from outbox').fetchone()[0],
            }
assert mode in ['local', 'local-sync', 'performance', 'deletion']
trials = []
for attempt in range(3 if mode == 'performance' else 1):
    run('shell', 'am', 'force-stop', package)
    before = snapshot() if mode in ['local', 'local-sync'] else None
    if before is not None:
        assert before == {'projects': 1, 'entries': 1, 'amount': 10, 'pending': 2}, before
    start = time.monotonic()
    launch = run('shell', 'am', 'start', '-W', '-n', activity)
    pid = run('shell', 'pidof', package)
    marker = {'local': 'KODO_RESTART_PASSED', 'local-sync': 'KODO_RESTART_SYNC_PASSED', 'performance': 'KODO_PERF_READY', 'deletion': 'KODO_DELETE_RECOVERED'}[mode]
    logs = ''
    while time.monotonic() - start < 30:
        logs = run('logcat', '-d', '--pid=' + pid, '-s', 'flutter:I')
        if marker in logs:
            break
        time.sleep(.1)
    else:
        raise RuntimeError('Restart did not reach the verified populated UI')
    elapsed = (time.monotonic() - start) * 1000
    matches = re.findall(r'KODO_PERF_READY (\{.*\})', logs)
    trial = {'same_apk_force_stop_relaunch': True, 'host_launch_to_verified_ui_ms': round(elapsed, 2), 'am_start': launch}
    if matches:
        trial['app_verified'] = json.loads(matches[-1])
    if before:
        # Stop before copying the WAL-consistent file set again.
        run('shell', 'am', 'force-stop', package)
        trial['before'] = before
        trial['after'] = snapshot()
        assert trial['after'] == {**before, 'pending': 0 if mode == 'local-sync' else before['pending']}
        run('shell', 'am', 'start', '-W', '-n', activity)
        time.sleep(3)
    trials.append(trial)
    with open(folder / (mode + '-same-install-restart.png'), 'wb') as f:
        subprocess.run([adb, '-s', device, 'exec-out', 'screencap', '-p'], stdout=f, check=True)
(folder / (mode + '-restart.json')).write_text(json.dumps({'mode': mode, 'trials': trials, 'timing_note': 'Host stopwatch includes adb launch and polling overhead; process cold, filesystem caches retained.'}, ensure_ascii=False, indent=2) + '\n')
print('PASS Android same-install restart: ' + json.dumps(trials, ensure_ascii=False))
