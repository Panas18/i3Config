# Lightweight desktop tools

Reviewed and installed on Ubuntu 26.04 / X11 i3, 20 October 2026. The goal is a
coherent settings menu without adding a full desktop environment or resident
settings daemon. The new hub, submenus, calendar and appearance editor exit
when closed. Existing NetworkManager/BlueZ/audio services remain responsible
for the hardware.

## Selected additions

| Feature | Implementation | Installation / idle impact |
| --- | --- | --- |
| Searchable settings hub | Rofi + `i3-settings`, matching Mocha colors | New local helper; no idle process |
| Wi-Fi/network menu | Pinned `networkmanager-dmenu` with Rofi | New local script; existing libnm/PyGObject; passwords obscured |
| Bluetooth menu | BlueZ D-Bus saved/connected device list | New local helper; no periodic scan; Blueman handles new pairing |
| Appearance | LXAppearance GTK3 | New local application; no settings daemon |
| Calendar | `i3-calendar`, single-instance GTK3 popup | New local helper; exits on focus loss / Escape |
| Sound/output settings | Pavucontrol | Reuse installed app, open on demand |
| Displays / profiles | ARandR + Autorandr | Reuse installed apps and existing display watcher |
| Wallpaper | Existing preview picker + feh | Reuse current implementation |
| Notifications | Rofi menu + dunstctl | Reuse Dunst; pause/resume/history, no extra watcher |
| Power profiles | powerprofilesctl | Shown when existing system service responds; no extra power manager |
| Clipboard / screenshots | CopyQ / Flameshot | Reuse existing tools; no additional copies |
| Task manager | htop in Kitty | Reuse installed htop; no dashboard polling while closed |
| Disk usage | Baobab | Reuse installed scanner; scans only when launched |
| Shortcut reference | Rofi menu | New static reference; no background process |

Useful future additions, intentionally not installed automatically:

- A disk-health view through existing GNOME Disks, if you want SMART tests.
- Manual printer configuration if you actually use a printer.
- A password manager launcher for your chosen password manager.

Full GNOME/KDE/Xfce settings sessions, another panel, Conky, animated wallpaper,
blur, another system monitor daemon, and a second power-management daemon add
work or duplicate tools here. None were added. TLP was not installed alongside
the machine's existing power-profile service.

## Resource changes and evidence

- No new autostart entries or resident settings services.
- Removed a stale orphan `eww open control-center` client and a second Flameshot
  process after checking the active service/D-Bus owner. CopyQ's clipboard
  monitor child is intentional and was kept.
- Picom keeps GLX, damage tracking and soft shadows. Blur and fades are off;
  opaque fullscreen applications can bypass compositing after 300ms.
- Polybar surfaces are opaque. CPU polls every 5s; RAM, temperature and brightness
  every 15s; battery every 30s; volume every 3s. Music remains event driven. The
  clock uses Polybar's native date module; clicking it launches the calendar.
- A five-second sample with the desktop updating showed Polybar and Eww at
  0% CPU and Picom at 5.6% of **one core**. This excludes short-lived status
  children and is not a whole-system idle benchmark or a guaranteed limit.
- No `i3-settings`, network-menu, calendar or appearance process remains after
  the corresponding window closes. These additions have no resident idle RSS.
  Existing Polybar, Picom, Dunst, Eww, CopyQ and hardware services still use RAM.

To inspect real workload, use `htop` or `pidstat`; compare the same applications
and screen activity before drawing conclusions. RSS includes shared libraries
and must not be treated as private memory.

## Installation

For this machine the tools are installed under `~/.local/`; no root password or
full desktop package was required. Keep executable bits on `bin/i3-*`.

```sh
./bin/i3-install-settings "$PWD"
install -m755 bin/i3-center ~/.local/bin/
cp rofi/settings.rasi ~/.config/rofi/
cp eww/eww.yuck eww/eww.scss ~/.config/eww/
cp polybar/config.ini ~/.config/polybar/
cp picom/picom.conf ~/.config/picom/
cp i3/config ~/.config/i3/
eww reload
i3-msg reload
systemctl --user restart i3-polybar i3-picom
```

The installer preserves existing network/Rofi preferences. It copies the pinned
MIT network script and license into `~/.local/share/i3config/vendor/`. It requires
Python 3.11+, `python3-gi`, `gir1.2-nm-1.0`, `gir1.2-gtk-3.0`, `python3-dbus`, Rofi,
NetworkManager and BlueZ; these dependencies were already installed here.

If a system LXAppearance exists it is reused. Otherwise the Debian/Ubuntu
installer downloads its small distro package for UI resources, and builds the
pinned upstream executable with a user-local data path using the already
available GCC, pkg-config, GTK3/GModule and X11 development libraries. The build
has D-Bus integration disabled and needs no LXSession daemon. Its source and GPL
license are retained alongside the local executable. On another machine,
installing `lxappearance` with the distribution package manager is simpler if
those development libraries are unavailable. Nothing changes your theme until
you choose and apply it in the editor. Some GTK applications need reopening
to pick up changes when no XSettings daemon is running.

The Bluetooth menu exposes saved devices and power state without background
scanning. Use “Pair a new device / advanced settings” to open Blueman and its
pairing agent. Opening/cancelling the menu never powers off, disconnects, scans,
changes a power profile or switches displays automatically.

A laptop-only Autorandr profile is hidden in the settings menu while the lid is
closed. The existing display watcher still enforces lid safety after changes.

## Research and source choices

- [Rofi](https://github.com/davatorium/rofi): reuse the existing launcher and
  theme system for transient menus.
- [networkmanager-dmenu](https://github.com/firecat53/networkmanager-dmenu):
  NetworkManager connection management via launcher menus; the unmodified
  vendored version and its revision are recorded in `vendor/`.
- [LXAppearance](https://github.com/lxde/lxappearance): a focused GTK theme/icon/font
  editor. Local build revision: `dc5d5b313c9c46e91e9205b54ae6ad92e7910f64`.
- [Xfce settings](https://github.com/xfce-mirror/xfce4-settings) includes a manager,
  editor and daemon. Reusing the current standalone tools is the narrower fit
  for this installation.
- [rofi-bluetooth](https://github.com/nickclyde/rofi-bluetooth) was evaluated;
  a small saved-device menu plus the existing Blueman pairing UI avoids adding
  another shell-based scanning/pairing workflow.
- [Picom manual](https://picom.app/): damage tracking and opaque-fullscreen
  unredirection options used for the compositor budget.

Validation: automated helper regressions, i3 config validation, shell syntax,
menu cancellation checks, actual Wi-Fi/settings/appearance launches and live
calendar navigation/dismissal. No real network disconnect, Bluetooth pairing,
new power profile or monitor layout was applied during menu verification.
