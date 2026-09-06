"""Run Godot integration scripts serially, treating engine errors as failures too."""
from pathlib import Path
import json
import shutil
import subprocess
import sys

root = Path(__file__).resolve().parents[2]
godot = shutil.which('godot')
if not godot:
    raise SystemExit('Godot 4.6.2 must be on PATH')
tests = [root / path for path in sys.argv[1:]] if len(sys.argv) > 1 else sorted((root / 'tests').glob('test_*.gd'))
results = []
for path in tests:
    try:
        result = subprocess.run([godot, '--headless', '--path', str(root), '--script', str(path)], capture_output=True, text=True, timeout=60)
        log = result.stdout + result.stderr
        passed = result.returncode == 0 and 'ERROR:' not in log
    except subprocess.TimeoutExpired as error:
        passed, log = False, str(error)
    results.append({'test': path.name, 'passed': passed, 'output': log})
    print(('PASS ' if passed else 'FAIL ') + path.name, flush=True)
    if not passed:
        print(log, flush=True)
out = root / 'output' / 'rebirth'
out.mkdir(parents=True, exist_ok=True)
(out / 'test-results.json').write_text(json.dumps(results, indent=2, ensure_ascii=False))
print(f'{sum(r["passed"] for r in results)}/{len(results)} passed')
raise SystemExit(0 if all(r['passed'] for r in results) else 1)
