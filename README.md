# Ubuntu configuration

Configuration files for i3, i3blocks, Kitty, tmux, zsh and Neovim.
The macOS terminal/editor configuration is on `macos`.

This branch contains configuration only: no installers, utility scripts, test
scripts, binaries or vendored plugins. The full setup is preserved locally on
`codex/local-setup`, which is not pushed.

## Existing-machine dependencies

The custom i3 features use runtime helpers already installed on this Ubuntu
machine. Their implementations are intentionally excluded from this branch:

| Installed command | Used for |
| --- | --- |
| `~/.local/bin/i3-session-start` | i3 session startup and applets |
| `~/.local/bin/i3-control`, `i3-brightness` | Audio, laptop backlight and external software dimming |
| `~/.local/bin/i3-status` | Emoji status blocks and usage bars |
| `~/.local/bin/i3-wallpaper` | Wallpaper selection and restoration |
| `~/.local/bin/i3-displays` | Lid handling and external display layout |

The systemd user service also needs `i3-displays`. These features are not
self-contained in a fresh clone. Keep the installed helpers when applying these
configs to this machine; provide equivalent helpers before using them elsewhere.

## File locations and packages

Back up existing files before manually copying configuration.

| Repository | Home-directory target |
| --- | --- |
| `.zshrc` | `~/.zshrc` |
| `i3/`, `i3blocks/`, `kitty/`, `tmux/`, `nvim/` | Corresponding directories in `~/.config/` |
| `tmux/tmux.conf` | `~/.tmux.conf` for compatibility |
| `systemd/user/i3-displays.service` | `~/.config/systemd/user/i3-displays.service` |

Required desktop packages include i3-wm, i3blocks, Kitty, tmux, zsh, feh, rofi,
NetworkManager/nm-applet, Blueman/BlueZ, PipeWire/WirePlumber, pavucontrol,
brightnessctl, dunst, picom, policykit-1-gnome, xss-lock/i3lock, playerctl,
Flameshot, xclip, Fira Code and Noto Color Emoji. App shortcuts also use nautilus
and ranger. Use an X11 i3 login session.

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
- Super+Ctrl+w: wallpaper picker; Super+Ctrl+Shift+l: lock.
- Super+Shift+c: reload i3; Super+Shift+r: restart i3.
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
and TypeScript LSP attachment. Runtime helpers were tested locally before being
excluded from this config-only branch. macOS runtime behaviour needs validation
on a Mac.
