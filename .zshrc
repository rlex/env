# --- ZSH Options ---
unsetopt BG_NICE
setopt NO_HUP
setopt AUTO_CD

# --- History ---
HISTFILE="$HOME/.zsh-history"
SAVEHIST=10000
HISTSIZE=10000
# share_history implies append_history and inc_append_history
setopt share_history
setopt extended_history
setopt hist_expire_dups_first
setopt hist_ignore_dups
setopt hist_ignore_space
setopt hist_verify

# --- Autoloads ---
autoload -U colors; colors
autoload -U edit-command-line

# --- Completion Configuration ---
# Homebrew ZSH setup
if [[ -d /usr/local/share/zsh/site-functions ]]; then
  fpath=(/usr/local/share/zsh/site-functions $fpath)
fi
if [[ -d /opt/homebrew/share/zsh-completions ]]; then
  fpath=(/opt/homebrew/share/zsh-completions $fpath)
fi

# Re-run compinit to pick up the new fpath changes
autoload -U compinit; compinit -i

# 1. Matcher/Fuzzy Logic
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' # Case-insensitive
zstyle ':completion:*::::' completer _expand _complete _ignored _approximate # Search order

# 2. Visuals & UX
LISTMAX=1000
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' list-prompt '%SAt %p: Hit TAB for more, or the character to insert%s'
zstyle ':completion:*' select-prompt '%SScrolling active: current selection at %p%s'
zstyle ':completion:*:messages' format '%d'
zstyle ':completion:*:warnings' format 'No matches for: %d'

# 3. Filtering
zstyle ':completion:*:*:*:users' ignored-patterns '*'
zstyle ':completion:*:*:ssh:*:hosts' ignored-patterns '_*' 'loopback' 'localhost'

# 4. Misc tuning
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'
zstyle ':completion::complete:*' use-cache on
zstyle ':completion::complete:*' cache-path ~/.zsh/cache

# --- Keybindings ---
bindkey '^[[A' history-beginning-search-backward
bindkey '^[[B' history-beginning-search-forward

# Kitty fix for option + left-right
bindkey "\e[1;3C" emacs-forward-word
bindkey "\e[1;3D" emacs-backward-word

# --- Prompt Logic ---
# Use complex fonts only on compatible terminal
if [[ ${TERM} =~ ("256color") ]]; then
  prompt_symbol="❯"
  ssh_symbol=" ⇣⇡"
else
  prompt_symbol=">"
  ssh_symbol=" <=>"
fi

# Right prompt
RPS1='$(kube_ps1)$(git_prompt_string)'

# Precmd hook - ssh connection indicator
function precmd() {
  # Determine color based on last command exit status
  local status_color="%{$fg[green]%}"
  [[ $? -ne 0 ]] && status_color="%{$fg[red]%}"
  if [[ -z "${SSH_CLIENT}" ]]; then
    # Local Prompt
    PROMPT="${status_color}${prompt_symbol} %{$reset_color%}"
  else
    # SSH Prompt
    PROMPT="%{$fg[green]%}%n%{$fg[cyan]%}@%M%{$fg_bold[blue]%}${ssh_symbol} ${status_color}${prompt_symbol} %{$reset_color%}"
  fi
}

# --- Environment Loading ---
for envfile in ~/.rc/sh.d/[LSZ][0-9][0-9]*[^~](N); do
  source "$envfile"
done