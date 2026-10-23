#!/bin/sh
# Build a generic lmi image: no Wi-Fi profile, no SSH keys, no personal files.
# The image boots to Phosh; the user logs in and configures Wi-Fi in Settings.
set -eu

: "${GENERIC_PASSWORD:=147147}"
: "${HOME:?set HOME}"
PMB="${PMB:-$HOME/pmbootstrap}"

cd "$PMB"
python3 pmbootstrap.py --as-root install --no-recommends \
    --password "$GENERIC_PASSWORD"

python3 pmbootstrap.py --as-root export

cat <<'EOF'
Done. Images are in /tmp/postmarketOS-export/.
Before publishing, verify that the image contains:
  - no /etc/NetworkManager/system-connections/*.nmconnection with personal credentials
  - no /root/.ssh/authorized_keys or private keys
  - no personal files in /home/user
EOF
