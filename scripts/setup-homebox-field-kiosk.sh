#!/usr/bin/env bash
set -euo pipefail

KIOSK_USER="kiosk"
KIOSK_URL="https://homebox.home.arpa:30022/field/"
KIOSK_HOSTNAME="homebox-field-kiosk"

echo "==> Confirming this looks like NVIDIA Jetson/L4T"
if [ -f /etc/nv_tegra_release ]; then
  cat /etc/nv_tegra_release
else
  echo "WARNING: /etc/nv_tegra_release not found. This may not be NVIDIA L4T."
fi

echo "==> Priming sudo"
sudo -v

echo "==> Setting hostname to ${KIOSK_HOSTNAME}"
sudo hostnamectl set-hostname "${KIOSK_HOSTNAME}"

echo "==> Updating apt"
sudo apt update

echo "==> Installing lightweight kiosk packages"
sudo apt install -y \
  xserver-xorg \
  xinit \
  x11-xserver-utils \
  openbox \
  unclutter \
  chromium-browser \
  ca-certificates \
  curl \
  dbus-x11

echo "==> Creating kiosk user if needed"
if ! id "${KIOSK_USER}" >/dev/null 2>&1; then
  sudo useradd -m -s /bin/bash "${KIOSK_USER}"
fi

for group in video audio input netdev; do
  if getent group "$group" >/dev/null 2>&1; then
    sudo usermod -aG "$group" "${KIOSK_USER}"
  else
    echo "WARNING: group $group not found; skipping"
  fi
done

echo "==> Creating kiosk Chromium launcher"
sudo tee "/home/${KIOSK_USER}/start-homebox-kiosk.sh" >/dev/null <<SCRIPT
#!/usr/bin/env bash
set -u

KIOSK_URL="${KIOSK_URL}"
KIOSK_USER="${KIOSK_USER}"

export DISPLAY=:0
export XDG_RUNTIME_DIR="/tmp/runtime-${KIOSK_USER}"
mkdir -p "\$XDG_RUNTIME_DIR"
chmod 700 "\$XDG_RUNTIME_DIR"

xset s off || true
xset -dpms || true
xset s noblank || true

unclutter -idle 0.5 -root &

until getent hosts homebox.home.arpa >/dev/null 2>&1; do
  echo "Waiting for homebox.home.arpa to resolve..."
  sleep 2
done

until curl -k --connect-timeout 3 -Is "\$KIOSK_URL" >/dev/null 2>&1; do
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
  "\$CHROME" \
    --kiosk \
    --app="\$KIOSK_URL" \
    --start-fullscreen \
    --noerrdialogs \
    --disable-infobars \
    --disable-session-crashed-bubble \
    --disable-features=TranslateUI \
    --overscroll-history-navigation=0 \
    --disable-pinch \
    --user-data-dir="/home/${KIOSK_USER}/.config/chromium-kiosk" \
    --ignore-certificate-errors

  sleep 5
done
SCRIPT

# Fix accidental DEL guard if shell/editor mangles here-doc expansion; the final file should use literal kiosk username.
sudo sed -i 's#/tmp/runtime-.*kiosk#/tmp/runtime-kiosk#' "/home/${KIOSK_USER}/start-homebox-kiosk.sh"

sudo chmod +x "/home/${KIOSK_USER}/start-homebox-kiosk.sh"
sudo chown "${KIOSK_USER}:${KIOSK_USER}" "/home/${KIOSK_USER}/start-homebox-kiosk.sh"

echo "==> Creating .xinitrc"
sudo tee "/home/${KIOSK_USER}/.xinitrc" >/dev/null <<SCRIPT
#!/usr/bin/env bash
openbox-session &
exec /home/${KIOSK_USER}/start-homebox-kiosk.sh
SCRIPT

sudo chmod +x "/home/${KIOSK_USER}/.xinitrc"
sudo chown "${KIOSK_USER}:${KIOSK_USER}" "/home/${KIOSK_USER}/.xinitrc"

echo "==> Creating .bash_profile to start X on tty1"
sudo tee "/home/${KIOSK_USER}/.bash_profile" >/dev/null <<'SCRIPT'
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
  startx -- -nocursor -s 0 -dpms vt1
fi
SCRIPT

sudo chown "${KIOSK_USER}:${KIOSK_USER}" "/home/${KIOSK_USER}/.bash_profile"

echo "==> Configuring tty1 autologin"
sudo mkdir -p /etc/systemd/system/getty@tty1.service.d

sudo tee /etc/systemd/system/getty@tty1.service.d/autologin.conf >/dev/null <<SCRIPT
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin ${KIOSK_USER} --noclear %I \$TERM
SCRIPT

echo "==> Disabling graphical display manager if present"
sudo systemctl disable gdm3 2>/dev/null || true
sudo systemctl disable lightdm 2>/dev/null || true
sudo systemctl disable slim 2>/dev/null || true

echo "==> Enabling tty autologin"
sudo systemctl daemon-reload
sudo systemctl enable getty@tty1.service

echo "==> Verification before reboot"
hostnamectl
cat /etc/nv_tegra_release || true
getent hosts homebox.home.arpa
curl -k -I "${KIOSK_URL}"
command -v chromium-browser || command -v chromium || command -v google-chrome
systemctl status getty@tty1.service --no-pager || true

echo
echo "Setup complete. Reboot with: sudo reboot"
echo "After reboot, the Jetson should open: ${KIOSK_URL}"
