#!/bin/bash

NAS_IP="10.1.20.2"
NAS_SHARE="dev"
MOUNT_POINT="/mnt/dev"
CREDS_FILE="/etc/samba/credentials_nas"

echo "=== NAS Mount Setup ==="

# Install cifs-utils
echo "[1/4] Installing cifs-utils..."
sudo apt install -y cifs-utils

# Create credentials file
echo "[2/4] Setting up credentials..."
sudo mkdir -p /etc/samba
if [ ! -f "$CREDS_FILE" ]; then
  read -sp "Enter SMB password for alex: " SMB_PASS
  echo
  sudo bash -c "cat > $CREDS_FILE << EOF
username=alex
password=$SMB_PASS
EOF"
  sudo chmod 600 "$CREDS_FILE"
else
  echo "  Credentials file already exists, skipping."
fi

# Create systemd mount unit
echo "[3/4] Creating systemd mount..."
sudo mkdir -p "$MOUNT_POINT"
sudo bash -c "cat > /etc/systemd/system/mnt-dev.mount << EOF
[Unit]
Description=NAS Dev Share
After=network-online.target
Wants=network-online.target

[Mount]
What=//$NAS_IP/$NAS_SHARE
Where=$MOUNT_POINT
Type=cifs
Options=credentials=$CREDS_FILE,vers=3.1.1,uid=1000,gid=1000,file_mode=0775,dir_mode=0775,iocharset=utf8,soft,nounix,_netdev

[Install]
WantedBy=multi-user.target
EOF"

# Enable and mount
echo "[4/4] Mounting..."
sudo systemctl daemon-reload
sudo systemctl enable --now mnt-dev.mount

# Verify
if mountpoint -q "$MOUNT_POINT"; then
  echo ""
  echo "=== Done! NAS mounted at $MOUNT_POINT ==="
  ls "$MOUNT_POINT"
else
  echo ""
  echo "=== Mount failed. Check: sudo systemctl status mnt-dev.mount ==="
fi
