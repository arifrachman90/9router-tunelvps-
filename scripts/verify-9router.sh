#!/usr/bin/env bash
set -euo pipefail

echo '=== systemd status ==='
systemctl status 9router.service --no-pager | sed -n '1,40p'

echo
echo '=== model list ==='
curl -sS http://127.0.0.1:20128/v1/models | sed -n '1,60p'

echo
echo '=== comboall test ==='
python3 - <<'PY'
import json, urllib.request
url='http://127.0.0.1:20128/v1/chat/completions'
payload={
  'model':'comboall',
  'messages':[{'role':'user','content':'Reply with exactly: COMBOALL_OK'}],
  'max_tokens':20,
  'temperature':0
}
req=urllib.request.Request(url,data=json.dumps(payload).encode(),headers={'Content-Type':'application/json'})
with urllib.request.urlopen(req, timeout=60) as r:
    print(r.read().decode())
PY
