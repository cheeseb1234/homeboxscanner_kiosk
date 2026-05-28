#!/usr/bin/env bash
set -euo pipefail

echo '=== Installing xterm and creating openbox right-click menu with terminal ==='

sudo apt install -y xterm

echo '--- Creating openbox menu.xml ---'
sudo mkdir -p /home/kiosk/.config/openbox

sudo tee /home/kiosk/.config/openbox/menu.xml >/dev/null << 'MENU'
<?xml version="1.0" encoding="utf-8"?>
<openbox_menu xmlns="http://openbox.org/"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://openbox.org/ file:///usr/share/openbox/menu.xsd">
<menu id="root-menu" label="Applications">
  <item label="Terminal (xterm)">
    <action name="Execute"><command>xterm</command></action>
  </item>
  <item label="Chromium (new window)">
    <action name="Execute"><command>chromium-browser --noerrdialogs --ignore-certificate-errors https://homebox.home.arpa:30022/field/</command></action>
  </item>
  <item label="Reload Openbox">
    <action name="Reconfigure"/>
  </item>
  <separator/>
  <item label="Log Out Kiosk">
    <action name="Exit"/>
  </item>
</menu>
</openbox_menu>
MENU

sudo chmod 644 /home/kiosk/.config/openbox/menu.xml
sudo chown -R kiosk:kiosk /home/kiosk/.config/openbox

echo '=== WiFi watchdog - systemd timer every 5min ==='
sudo tee /usr/local/bin/wifi-watchdog.sh >/dev/null << 'WDOG'
#!/usr/bin/env bash
set -euo pipefail
WLAN="wlan0"
PING_TARGET="192.168.1.1"
if ! ip -4 addr show dev "$WLAN" | grep -q "inet "; then
  logger -t wifi-watchdog "wlan0 has no IP - restarting network"
  nmcli dev connect "$WLAN" 2>/dev/null || ifup "$WLAN" 2>/dev/null || true
  logger -t wifi-watchdog "network restart attempted"
  exit 1
fi
if ! ping -c1 -W3 "$PING_TARGET" >/dev/null 2>&1; then
  logger -t wifi-watchdog "gateway $PING_TARGET unreachable - restarting wpa"
  systemctl restart wpa_supplicant || true
  sleep 3
  ifup "$WLAN" 2>/dev/null || true
  exit 1
fi
exit 0
WDOG
sudo chmod +x /usr/local/bin/wifi-watchdog.sh

sudo tee /etc/systemd/system/wifi-watchdog.service >/dev/null << 'SVC'
[Unit]
Description=WiFi connectivity watchdog
After=network.target
[Service]
Type=oneshot
ExecStart=/usr/local/bin/wifi-watchdog.sh
SVC

sudo tee /etc/systemd/system/wifi-watchdog.timer >/dev/null << 'TIM'
[Unit]
Description=Check WiFi every 5 minutes
[Timer]
OnBootSec=2min
OnUnitActiveSec=5min
[Install]
WantedBy=timers.target
TIM

sudo systemctl daemon-reload
sudo systemctl enable wifi-watchdog.timer
sudo systemctl start wifi-watchdog.timer
echo '=== wifi-watchdog timer started ==='

echo '=== Fixes applied. Restarting tty1 to reload openbox config ==='
sudo systemctl restart getty@tty1.service
echo 'Done.'
