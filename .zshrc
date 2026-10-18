export PATH="$HOME/.local/bin:$PATH"
export EDITOR=nvim
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=gentoo

# Let Oh My Zsh initialise completion once. zsh-autocomplete also initialises
# completion and conflicts with this setup, so use native menus + autosuggestions.
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*'
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{blue}%d%f'
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
[[ -f $ZSH/oh-my-zsh.sh ]] && source "$ZSH/oh-my-zsh.sh"
bindkey -e
bindkey '^I' expand-or-complete
bindkey '^[[Z' reverse-menu-complete
bindkey '^[[C' forward-char
bindkey '^ ' autosuggest-accept
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt APPEND_HISTORY SHARE_HISTORY HIST_IGNORE_DUPS
alias vim=nvim

export NVM_DIR="$HOME/.nvm"
[[ -s $NVM_DIR/nvm.sh ]] && source "$NVM_DIR/nvm.sh"
if [[ -o interactive && -t 0 && -z $TMUX && ${I3CONFIG_NO_TMUX:-0} != 1 ]] && command -v tmux >/dev/null; then
  tmux new-session -A -s main
fi
