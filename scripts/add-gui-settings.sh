#!/usr/bin/env bash
set -euo pipefail

echo '=== Installing lightweight GUI settings tools ==='

sudo apt install -y --no-install-recommends \
  arandr \
  lxappearance \
  lxrandr

echo '=== Updating openbox menu with GUI settings entries ==='

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

  <separator/>

  <menu id="settings-menu" label="Display &amp; Scaling">
    <item label="ARandR (display layout, resolution, scale)">
      <action name="Execute"><command>arandr</command></action>
    </item>
    <item label="LXAppearance (fonts, themes, cursor size)">
      <action name="Execute"><command>lxappearance</command></action>
    </item>
    <item label="Set scale 1.0x (100%)">
      <action name="Execute"><command>sh -c 'xrandr --output HDMI-0 --scale 1.0x1.0 2>/dev/null || xrandr --output HDMI-1 --scale 1.0x1.0 2>/dev/null || notify-send "No HDMI display found for scale reset"'</command></action>
    </item>
    <item label="Set scale 1.25x (125%)">
      <action name="Execute"><command>sh -c 'xrandr --output HDMI-0 --scale 1.25x1.25 2>/dev/null || xrandr --output HDMI-1 --scale 1.25x1.25 2>/dev/null || notify-send "No HDMI display found"'</command></action>
    </item>
    <item label="Set scale 1.5x (150%)">
      <action name="Execute"><command>sh -c 'xrandr --output HDMI-0 --scale 1.5x1.5 2>/dev/null || xrandr --output HDMI-1 --scale 1.5x1.5 2>/dev/null || notify-send "No HDMI display found"'</command></action>
    </item>
    <item label="Set scale 2.0x (200%)">
      <action name="Execute"><command>sh -c 'xrandr --output HDMI-0 --scale 2.0x2.0 2>/dev/null || xrandr --output HDMI-1 --scale 2.0x2.0 2>/dev/null || notify-send "No HDMI display found"'</command></action>
    </item>
  </menu>

  <separator/>

  <item label="Reload Openbox">
    <action name="Reconfigure"/>
  </item>
  <item label="Log Out Kiosk">
    <action name="Exit"/>
  </item>
</menu>
</openbox_menu>
MENU

sudo chmod 644 /home/kiosk/.config/openbox/menu.xml
sudo chown -R kiosk:kiosk /home/kiosk/.config/openbox

echo '=== Adding scale persistence helper ==='

# Create a persistent xrandr scale script that can be called from menu
sudo tee /usr/local/bin/kiosk-scale >/dev/null << 'SCALE'
#!/usr/bin/env bash
set -euo pipefail
# Usage: kiosk-scale 1.0 | 1.25 | 1.5 | 2.0
SCALE="${1:-1.0}"
OUTPUTS="HDMI-0 HDMI-1 HDMI2 HDMI1"
OUT=""
for o in $OUTPUTS; do
  if xrandr | grep -q "^$o connected"; then
    OUT="$o"
    break
  fi
done
if [ -z "$OUT" ]; then
  zenity --error --text="No HDMI display found" 2>/dev/null || notify-send "kiosk-scale: no HDMI display found" 2>/dev/null || echo "ERROR: No HDMI display found"
  exit 1
fi
xrandr --output "$OUT" --scale "${SCALE}x${SCALE}"
CUR="$HOME/.config/kiosk-scale"
echo "$SCALE" > "$CUR"
echo "Display $OUT scaled to ${SCALE}x"
SCALE
sudo chmod +x /usr/local/bin/kiosk-scale

echo '=== Display scaling applied (detecting connected output) ==='

# Determine connected HDMI output
OUTPUT=""
for o in HDMI-0 HDMI-1 HDMI2 HDMI1; do
  if xrandr | grep -q "^$o connected"; then
    OUTPUT="$o"
    break
  fi
done

if [ -n "$OUTPUT" ]; then
  CURRENT_RES=$(xrandr | grep "^$OUTPUT connected" | grep -oP '\d+x\d+' | head -1)
  echo "Connected display: $OUTPUT ($CURRENT_RES)"
  if [ -f /home/kiosk/.config/kiosk-scale ]; then
    PREV_SCALE=$(cat /home/kiosk/.config/kiosk-scale)
    echo "Restoring previous scale: ${PREV_SCALE}x"
    xrandr --output "$OUTPUT" --scale "${PREV_SCALE}x${PREV_SCALE}"
  fi
else
  echo "No HDMI display detected - skipping xrandr scaling"
fi

echo '=== Reloading openbox config ==='
openbox --reconfigure 2>/dev/null || true

echo '=== Done. Right-click for Display & Scaling menu ==='
