# Powerlevel10k instant prompt
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-fzf-history-search)

source $ZSH/oh-my-zsh.sh

# Brew plugins
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme

# fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Aliases
alias vim=nvim

# Editor
export EDITOR=nvim
export TERMINAL="ghostty"

# p10k
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# aliases
alias ghostty-config='nvim ~/Library/Application\ Support/com.mitchellh.ghostty/config'
alias aerospace-config='nvim ~/.aerospace.toml'
alias karabiner-config='nvim ~/.config/karabiner/karabiner.json'
alias zshrc='nvim ~/.zshrc'
