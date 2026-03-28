# 9router on VPS (No Windows localhost)

Simple step-by-step guide to run **9router directly on a VPS** so OpenClaw does **not** depend on Windows localhost, ngrok, or Cloudflare tunnel.

This is the setup that keeps 9router alive on the VPS itself.

---

## Goal

At the end, you will have:

- `9router` running on the VPS
- OpenAI-compatible endpoint at:

```bash
http://127.0.0.1:20128/v1
```

- `9router` managed by `systemd`
- auto-start on reboot
- OpenClaw pointing to the VPS-local 9router endpoint

---

## 1) Prepare the VPS

Make sure Node.js and npm are available:

```bash
node -v
npm -v
```

If not installed:

```bash
sudo apt update
sudo apt install -y curl ca-certificates
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt install -y nodejs
```

Verify:

```bash
node -v
npm -v
```

---

## 2) Install 9router

Install globally:

```bash
sudo npm install -g 9router
```

Check:

```bash
9router --help
```

---

## 3) Run 9router once manually

Start it once to initialize files and confirm it works:

```bash
9router -H 127.0.0.1 -p 20128 --no-browser --skip-update
```

If it starts correctly, you should see something like:

```bash
Server: http://127.0.0.1:20128
```

Stop it after confirming.

---

## 4) Create a systemd service

Create the service file:

```bash
sudo tee /etc/systemd/system/9router.service >/dev/null <<'UNIT'
[Unit]
Description=9router local model router
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/root
ExecStart=/usr/bin/9router -H 127.0.0.1 -p 20128 --no-browser --skip-update
Restart=always
RestartSec=3
Environment=HOME=/root

[Install]
WantedBy=multi-user.target
UNIT
```

Reload systemd and enable the service:

```bash
sudo systemctl daemon-reload
sudo systemctl enable 9router.service
sudo systemctl restart 9router.service
```

Check status:

```bash
systemctl status 9router.service --no-pager
```

Expected result:
- service = `active (running)`

---

## 5) Verify the local API endpoint

Test the model list endpoint:

```bash
curl http://127.0.0.1:20128/v1/models
```

If healthy, it should return JSON with models like:

- `comboall`
- `cx/gpt-5.4`
- `ag/gemini-3.1-pro-high`
- `ag/claude-sonnet-4-6`

---

## 6) Point OpenClaw to local 9router

Open your OpenClaw config and make sure the 9router provider uses:

```json
"9router": {
  "baseUrl": "http://127.0.0.1:20128/v1"
}
```

If needed, edit:

```bash
nano ~/.openclaw/openclaw.json
```

Then restart OpenClaw gateway:

```bash
openclaw gateway restart
```

---

## 7) Test a model through 9router

Quick test against local 9router:

```bash
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
```

Expected output contains:

```bash
COMBOALL_OK
```

---

## 8) Why this is better than Windows localhost + tunnel

This VPS-native setup means:

- no Windows terminal required
- no ngrok required
- no Cloudflare tunnel required
- no dependency on your PC being online
- service survives reboot with `systemd`

If your goal is **24/7 stability**, this is the correct setup.

---

## 9) Useful commands

Check service:

```bash
systemctl status 9router.service --no-pager
```

Restart service:

```bash
sudo systemctl restart 9router.service
```

View logs:

```bash
journalctl -u 9router.service -n 100 --no-pager
```

Check local endpoint:

```bash
curl http://127.0.0.1:20128/v1/models
```

Restart OpenClaw gateway:

```bash
openclaw gateway restart
```

---

## 10) Migration to a new VPS

When your old VPS expires:

1. provision new VPS
2. install Node.js
3. install `9router`
4. create `9router.service`
5. verify `http://127.0.0.1:20128/v1/models`
6. restore/update `~/.openclaw/openclaw.json`
7. restart OpenClaw gateway
8. run model test

That’s it.

---

## Optional helper scripts

This repo also includes:

- `scripts/install-9router-vps.sh`
- `scripts/verify-9router.sh`

Use them if you want a faster repeatable setup.

---

## Final note

If 9router is already running on the VPS, **do not point OpenClaw to ngrok or Cloudflare tunnel** unless you specifically need external exposure.

For OpenClaw on the same VPS, the safest endpoint is:

```bash
http://127.0.0.1:20128/v1
```

That is the simplest and most stable setup.
