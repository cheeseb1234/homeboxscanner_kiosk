#!/usr/bin/env bash
set -euo pipefail

echo '== before launcher chromium command =='
sudo sed -n '1,90p' /home/kiosk/start-homebox-kiosk.sh

sudo cp -a /home/kiosk/start-homebox-kiosk.sh "/home/kiosk/start-homebox-kiosk.sh.bak.browser-mode.$(date +%Y%m%d-%H%M%S)"

sudo tee /home/kiosk/start-homebox-kiosk.sh >/dev/null <<'SCRIPT'
#!/usr/bin/env bash
set -u

KIOSK_URL="https://homebox.home.arpa:30022/field/"
KIOSK_USER="kiosk"

export DISPLAY=:0
export XDG_RUNTIME_DIR="/tmp/runtime-kiosk"
mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"

xset s off || true
xset -dpms || true
xset s noblank || true

# Keep cursor visible. Do not run unclutter.

until getent hosts homebox.home.arpa >/dev/null 2>&1; do
  echo "Waiting for homebox.home.arpa to resolve..."
  sleep 2
done

until curl -k --connect-timeout 3 -Is "$KIOSK_URL" >/dev/null 2>&1; do
  echo "Waiting for HomeBox field URL..."
  sleep 3
done

if command -v chromium-browser >/dev/null 2>&1; then
  CHROME=chromium-browser
elif command -v chromium >/dev/null 2>&1; then
  CHROME=chromium
elif command -v google-chrome >/dev/null 2>&1; then
  CHROME=google-chrome
else
  echo "ERROR: no Chromium/Chrome executable found" >&2
  exit 1
fi

while true; do
  "$CHROME" \
    "$KIOSK_URL" \
    --start-maximized \
    --noerrdialogs \
    --disable-session-crashed-bubble \
    --overscroll-history-navigation=0 \
    --user-data-dir="/home/${KIOSK_USER}/.config/chromium-kiosk" \
    --ignore-certificate-errors

  sleep 5
done
SCRIPT

sudo chmod +x /home/kiosk/start-homebox-kiosk.sh
sudo chown kiosk:kiosk /home/kiosk/start-homebox-kiosk.sh

# Make sure X starts with visible cursor.
sudo cp -a /home/kiosk/.bash_profile "/home/kiosk/.bash_profile.bak.browser-mode.$(date +%Y%m%d-%H%M%S)"
sudo sed -i 's/startx -- -nocursor -s 0 -dpms vt1/startx -- -s 0 -dpms vt1/' /home/kiosk/.bash_profile

echo '== after launcher chromium command =='
sudo sed -n '1,90p' /home/kiosk/start-homebox-kiosk.sh

echo 'Browser mode configured: normal Chromium window with tabs, not kiosk/app/fullscreen.'
