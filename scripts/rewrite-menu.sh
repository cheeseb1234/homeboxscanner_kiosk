#!/usr/bin/env bash
set -euo pipefail
echo '=== Rewriting entire openbox menu.xml cleanly ==='
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

    <separator/>

    <item label="Reset to 100% (1.00x)">
      <action name="Execute"><command>kiosk-scale 1.00</command></action>
    </item>
    <item label="Scale 1.05x (105%)">
      <action name="Execute"><command>kiosk-scale 1.05</command></action>
    </item>
    <item label="Scale 1.10x (110%)">
      <action name="Execute"><command>kiosk-scale 1.10</command></action>
    </item>
    <item label="Scale 1.15x (115%)">
      <action name="Execute"><command>kiosk-scale 1.15</command></action>
    </item>
    <item label="Scale 1.20x (120%)">
      <action name="Execute"><command>kiosk-scale 1.20</command></action>
    </item>
    <item label="Scale 1.25x (125%)">
      <action name="Execute"><command>kiosk-scale 1.25</command></action>
    </item>
    <item label="Scale 1.50x (150%)">
      <action name="Execute"><command>kiosk-scale 1.50</command></action>
    </item>

    <separator/>

    <item label="Scale 0.95x (95%)">
      <action name="Execute"><command>kiosk-scale 0.95</command></action>
    </item>
    <item label="Scale 0.90x (90%)">
      <action name="Execute"><command>kiosk-scale 0.90</command></action>
    </item>
    <item label="Scale 0.85x (85%)">
      <action name="Execute"><command>kiosk-scale 0.85</command></action>
    </item>
    <item label="Scale 0.80x (80%)">
      <action name="Execute"><command>kiosk-scale 0.80</command></action>
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
echo '=== Menu rewritten. Reloading openbox via tty1 restart ==='
