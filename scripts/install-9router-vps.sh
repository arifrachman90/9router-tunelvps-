#!/usr/bin/env bash
set -euo pipefail

echo '[1/5] Checking Node.js and npm'
if ! command -v node >/dev/null 2>&1; then
  apt update
  apt install -y curl ca-certificates
  curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
  apt install -y nodejs
fi

node -v
npm -v

echo '[2/5] Installing 9router'
npm install -g 9router

echo '[3/5] Writing systemd service'
cat >/etc/systemd/system/9router.service <<'UNIT'
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

echo '[4/5] Enabling service'
systemctl daemon-reload
systemctl enable 9router.service
systemctl restart 9router.service

echo '[5/5] Verifying local API'
sleep 3
systemctl --no-pager --full status 9router.service | sed -n '1,40p'
curl -sS http://127.0.0.1:20128/v1/models | sed -n '1,40p'

echo 'Done.'
