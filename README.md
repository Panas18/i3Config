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
| `~/.local/bin/i3-status` | Emoji status blocks and usage bars |
| `~/.local/bin/i3-wallpaper` | Thumbnail wallpaper selection and restoration |
| `~/.local/bin/i3-lock` | Current wallpaper fitted to each display for i3lock |
| `~/.local/bin/i3-power-menu` | Rofi lock, suspend, logout, restart and shutdown menu |
| `~/.local/bin/i3-touchpad` | Enable libinput tap-to-click on login/reload |
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
| `systemd/user/i3-displays.service` | `~/.config/systemd/user/i3-displays.service` |

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
- Media and brightness keys use the installed runtime helpers.
- The bar shows temperature, battery, RAM used/total, disk free space, CPU
  load, network throughput, time, volume and brightness. CPU/RAM/disk have explicit
  labels and usage bars. Signals 10 and 11 refresh brightness and volume.
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
