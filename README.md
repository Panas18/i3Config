# Ubuntu configuration

Configuration files for i3, i3blocks, Kitty, tmux, zsh and Neovim.
The macOS terminal/editor configuration is on `macos`.

This branch includes desktop configuration and the runtime helpers in `bin/`.
Installers, test scripts, binaries and vendored plugins are not included.

## Desktop helpers

Install the helpers at the paths used by the i3 configuration:

```sh
mkdir -p ~/.local/bin ~/.local/state/i3config
install -m 755 bin/i3-* ~/.local/bin/
```

Run these commands from the repository root. The helpers require an i3 X11
session; start the session normally so `XDG_SESSION_ID` identifies the login
session used by the lock listener.

| Installed command | Used for |
| --- | --- |
| `~/.local/bin/i3-session-start` | i3 session startup and applets |
| `~/.local/bin/i3-control`, `i3-brightness` | Audio, laptop backlight and external software dimming |
| `~/.local/bin/i3-notify` | Volume and brightness progress notifications via dunstify |
| `~/.local/bin/i3-audio` | Playback output selection and volume control |
| `~/.local/bin/i3-center`, `i3-status-value` | On-demand control center and widget values |
| `~/.local/bin/i3-status` | Emoji status blocks and usage bars |
| `~/.local/bin/i3-wallpaper` | Thumbnail wallpaper selection and restoration |
| `~/.local/bin/i3-lock` | Current wallpaper fitted to each display for i3lock |
| `~/.local/bin/i3-power-menu` | Rofi lock, suspend, logout, restart and shutdown menu |
| `~/.local/bin/i3-touchpad` | Enable touchpad tap-to-click and natural scrolling on login/reload |
| `~/.local/bin/i3-displays` | Lid handling and external display layout |

After copying the configuration and service, run `systemctl --user daemon-reload`
and log into i3. The session helper starts the display service and lock listener.
Put personal wallpapers in `~/Pictures/Wallpapers`; the picker also includes
`/usr/share/backgrounds`. A `default.png` in the personal wallpaper directory is
the fallback when no saved wallpaper exists. Wallpaper choices and generated
previews stay in the user's state/cache directories and are not tracked.

## File locations and packages

Back up existing files before manually copying configuration.

| Repository | Home-directory target |
| --- | --- |
| `bin/i3-*` | `~/.local/bin/` (executable) |
| `.zshrc` | `~/.zshrc` |
| `i3/`, `i3blocks/`, `kitty/`, `tmux/`, `nvim/` | Corresponding directories in `~/.config/` |
| `tmux/tmux.conf` | `~/.tmux.conf` for compatibility |
| `systemd/user/*.service` | `~/.config/systemd/user/` |

Required desktop packages include i3-wm, i3blocks, Kitty, tmux, zsh, feh, rofi,
NetworkManager/nm-applet, Blueman/BlueZ, PipeWire/WirePlumber, pavucontrol,
brightnessctl, dunst, picom, policykit-1-gnome, xss-lock/i3lock, playerctl,
Flameshot, xclip, Fira Code and Noto Color Emoji. App shortcuts also use nautilus
and ranger. Helpers additionally need Python 3, Pillow (`python3-pil`),
libX11/libXi, xrandr, xset, libnotify (`notify-send`), and systemd/logind.
Use an X11 i3 login session.

Zsh needs Oh My Zsh at `~/.oh-my-zsh` and the zsh-autosuggestions and
zsh-syntax-highlighting custom plugins. Tmux needs TPM at `~/.tmux/plugins/tpm`;
prefix + I installs the plugins listed in tmux.conf. Kitty starts zsh, which
attaches to the `main` tmux session. `I3CONFIG_NO_TMUX=1` disables automatic attach.

## Neovim

The configuration targets Neovim 0.11 with the locked Treesitter master branch.
Git, a C compiler, make, unzip, curl, Python/venv, Node/npm and ripgrep are needed.
`lazy.nvim` bootstraps itself and uses `nvim/lazy-lock.json`. Run `:Lazy restore`
to apply the locked versions and `:MasonToolsInstall` to install configured
language tools, including Markdown linting. Unavailable optional linters are
skipped so they cannot block file opening. Go is needed to build the configured Go debugger. System clangd
and clang-format are reused when installed on Ubuntu.

The parser list is in `nvim/parsers.lua`; Treesitter installs missing parsers.
Use `:checkhealth` after installation. Copilot/Claude features require your own
accounts and the relevant CLI. Tab/Shift+Tab navigate completion; Enter confirms;
Alt+l accepts a Copilot suggestion.

## Controls

- Super+Enter: Kitty; Super+Space: application launcher.
- Super+Ctrl+n / b / m: network, Bluetooth and audio settings.
- Super+Ctrl+w: wallpaper picker with thumbnail previews.
- Super+Shift+e: power menu; logout, restart and shutdown ask for confirmation.
- Super+Shift+c: reload i3. Separate lock, sleep, shutdown and restart shortcuts are removed; use the power menu.
- Super+U / Super+N: volume up/down on the playback output. Alt+U / Alt+N also work.
- Media and brightness keys use the installed runtime helpers.
- Bar order: network name, battery, sound, brightness, temperature, CPU,
  RAM, storage, Bluetooth, network traffic, then full date/time.
  RAM/disk/CPU use four-cell usage graphs. Sound icons follow volume/mute;
  battery shows 🔌 when charging/full and 🪫 when low.
  Bluetooth × means off/unavailable, ✓ means on, and a number counts connected
  devices. Traffic uses K/M for KiB/s/MiB/s. Use nm-applet in the primary display’s system tray to select Wi-Fi networks. Click the network name or traffic, or press Super+Ctrl+N, for the floating connection editor; click Bluetooth for the floating Blueman manager.
  Volume/brightness changes show short progress notifications (requires dunstify,
  provided by Dunst); repeated changes replace the previous popup.
  Signals 10 and 11 refresh brightness and volume.
- Closing the lid with an external screen connected moves workspaces there;
  reopening it or unplugging the last external screen restores the laptop panel.
- Zsh: Tab completes; Right Arrow or Ctrl+Space accepts a suggestion.
- Tmux: Ctrl+b then Shift+t cycles Mocha, Gruvbox and Nord using native tmux
  configuration. Change the default `source-file` line to choose a startup theme.

## Review

The installed Ubuntu session passed i3 syntax validation, zsh interactive Tab and
history-suggestion checks, all three tmux palettes, Neovim startup/parser checks
and TypeScript LSP attachment. Runtime helpers are included in `bin/` and were tested locally. macOS runtime behaviour needs validation
on a Mac.

Click the sound indicator or press Super+Ctrl+M to open the floating
pavucontrol Output Devices tab. Choose the fallback/default output there;
use Playback to route existing apps and Configuration to enable HDMI/Bluetooth
profiles when needed.

Audio keys, bar and notifications follow the output used by playback (including
paused streams), falling back to the default output when no stream exists. With
multiple outputs playing, the default is preferred if active, otherwise one
active output is selected deterministically. `bin/i3-audio` requires `pactl`
from `pulseaudio-utils` (compatible with PipeWire).

Dunst theme: copy `dunst/dunstrc` to `~/.config/dunst/dunstrc` and run
`dunstctl reload`. Normal notifications expire after 7 seconds; critical alerts
remain until dismissed. Right-click dismisses one, middle-click dismisses all,
and left-click runs the default action when available. Media popups have
progress bars and are excluded from history. `dunstctl history-pop` recalls
a notification. Click the clock for a floating calendar (requires `zenity`).

## Desktop polish

Copy `picom/`, `rofi/`, and `eww/` into `~/.config/` alongside the other
configuration folders. Picom uses subtle shadows/fades with no blur.
Super+Ctrl+V opens CopyQ clipboard history; Super+V keeps its i3 split action.
Super+S toggles the Eww control center. CopyQ is started at login; Eww starts
on demand through `systemd/user/i3-eww.service` (copy it to
`~/.config/systemd/user/` and run `systemctl --user daemon-reload`). Install CopyQ and build Eww with X11 support if unavailable in apt.
The quick-settings panel contains only Network, Bluetooth and Power. It closes
when another window or workspace gains focus, and closes before launching a tool.
`i3-center-watch` subscribes to i3 events while the panel is open; it does not poll
in the background. Copy this helper along with `i3-center`.

Picom uses the accelerated GLX backend with subtle shadows, short fades and
10px window corners. `i3-picom.service` starts with the session and restarts on
failure. Copy the service to `~/.config/systemd/user/`, reload systemd, stop any
old manually launched Picom instance, and run `systemctl --user start i3-picom`.
Use `journalctl --user -u i3-picom -b` for diagnostics. If another graphics driver
has GLX problems, change `backend` to `"xrender"` in `picom/picom.conf` and restart
the service. Fullscreen unredirection is disabled to keep compositing consistent.

Eww build used: official tag `v0.6.0`, with the locked `time` dependency
updated from 0.3.34 to 0.3.36 for compatibility with the installed Rust compiler.
Build with `cargo build --release --locked --no-default-features --features x11 -j 2`
after `cargo update -p time@0.3.34 --precise 0.3.36`. Install the resulting
`target/release/eww` into `~/.local/bin/`; binaries are not tracked here.

Before building Eww, apply `eww/patches/ipc-timeout.patch` from this repository
to the Eww source (`git apply /path/to/i3Config/eww/patches/ipc-timeout.patch`).
This raises its IPC response timeout to 5 seconds so slower panel creation
does not trigger a second daemon.

## Polybar and display profiles

Install `polybar` (3.7 or newer), `autorandr`, `xdotool` and Python 3. Copy `polybar/` to
`~/.config/polybar/`, all `bin/i3-*` helpers to `~/.local/bin/`, and the user
services to `~/.config/systemd/user/`. Run `systemctl --user daemon-reload`.
The session starts `i3-polybar.service`; the i3bar block is removed. The retained
`i3blocks/` config is an optional fallback rather than a second running panel.
Polybar uses Fira Code, DejaVu Sans and FontAwesome (monochrome icons).

The panel uses three separate rounded Mocha islands, with 12px gutters:

- **Left:** application launcher, i3 workspaces and the active window title.
- **Center:** previous/play-pause/next, a bounded MPRIS track title and date/time.
- **Right:** CPU, memory, temperature, brightness, volume, battery and quick settings.

Wi-Fi names, Bluetooth and the tray are removed from the bar. Network and Bluetooth
settings live in quick settings (sliders icon or Super+S). Power actions are there
too, with the existing confirmation for shutdown/reboot/logout.
Scroll sound/brightness to change levels; right-click sound to mute; left-click
sound to choose an output. Click the date to toggle its detail. The launcher opens
apps on left click and the window switcher on right click. Music uses `playerctl`;
when no MPRIS player is running it displays “Nothing playing”. Track metadata is
sanitized before Polybar renders it.

`i3-polybar` calculates widths from the primary monitor and supervises the whole
group. A transparent dock reserves one 56px row; the three visible bars use
`override-redirect` so i3 does not stack them. The transparent reservation dock
has an empty X11 input shape so clicks reach the visible islands. On screens narrower than 1500px,
the brightness readout is omitted and titles are shortened; hardware brightness
keys still work. Under 1200px, the right island keeps temperature, sound, battery
and settings. The display watcher restarts the group when outputs change.

Save each desired monitor arrangement with `autorandr --save PROFILE_NAME`.
The current machine's docked arrangement is saved locally as `docked`.
Profiles contain hardware-specific display identifiers and stay in
`~/.config/autorandr/`, outside this repository. The existing display watcher
runs `autorandr --change` once when connected outputs change, then enforces
lid safety and refreshes Polybar/wallpaper. Avoid adding a second autorandr
polling loop. Unplug/open-lid handling still restores the laptop display.

Edit `polybar/config.ini` for colors and modules, `bin/i3-polybar` for geometry,
and `eww/eww.scss` for quick-settings styling. After copying changes into the
runtime directories, restart `i3-polybar.service` and run `eww reload`.
