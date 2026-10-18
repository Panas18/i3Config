# macOS terminal and editor configuration

Kitty, tmux, zsh and Neovim configuration only. Ubuntu desktop configuration is
on `linux`. No installers, standalone utility/test scripts, binaries,
backup files or vendored plugin checkouts are included.

## Manual placement

Back up existing files first. Copy `.zshrc` to `~/.zshrc`; copy `kitty/`, `tmux/`
and `nvim/` to their corresponding directories under `~/.config/`. Also place
`tmux/tmux.conf` at `~/.tmux.conf` for compatibility.

Install Kitty, tmux, zsh, Neovim, Git, Node/npm, Python/venv, ripgrep and compiler
tools separately. Kitty uses the built-in Menlo font and `/bin/zsh`. Zsh loads
Homebrew's environment when present, and requires Oh My Zsh at `~/.oh-my-zsh`
with the zsh-autosuggestions and zsh-syntax-highlighting custom plugins.

Kitty starts zsh, which attaches to the `main` tmux session. Set
`I3CONFIG_NO_TMUX=1` to skip automatic tmux attachment. Tab completes; Right Arrow
or Ctrl+Space accepts a suggestion; Shift+Tab cycles backwards.

Tmux requires TPM at `~/.tmux/plugins/tpm`; prefix + I installs the listed plugins.
Ctrl+b then Shift+t cycles Mocha, Gruvbox and Nord using native configuration.
Edit the default theme `source-file` line to select the startup theme.
The configuration inherits your PATH instead of replacing it with fixed paths.

## Neovim

The shared editor configuration and Treesitter pins target Neovim 0.11. Use
`:Lazy restore` for locked plugins and `:MasonToolsInstall` for configured language
tools, including Markdown linting. Missing optional linters are skipped rather
than aborting file opening. Go is needed to build the configured Go debugger. The parser list is in
`nvim/parsers.lua`; missing parsers install through Treesitter. Check compatibility
before changing the Neovim version or plugin pins.

Tab/Shift+Tab navigate completion, Enter confirms, and Alt+l accepts a Copilot
suggestion. Copilot and Claude integrations require your own account/CLI setup.

The shared settings passed Ubuntu syntax, interactive zsh completion, tmux theme,
Neovim parser and TypeScript LSP checks. These macOS-specific paths and defaults
were reviewed, but this branch has not been executed on a Mac.
