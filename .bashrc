# ── 1. Exit if not interactive -──────────────────────────────
[[ $- != *i* ]] && return

# ── 2. History ───────────────────────────────────────────────
export HISTFILE="${HOME}/.bash_history"
export HISTSIZE=10000
export HISTFILESIZE=200000
export HISTCONTROL="ignoreboth:erasedups"
export HISTTIMEFORMAT="%F %T "
shopt -s histappend cmdhist

# ── 3. Shell Options ──────────────────────────────────────────
shopt -s cdspell checkwinsize extglob globstar nocaseglob
shopt -s no_empty_cmd_completion

# ── 4. Readline: completion behaviour ──────────────────────────
bind 'set completion-ignore-case on'
bind 'set match-hidden-files on'
bind 'set show-all-if-ambiguous on'
bind 'set colored-stats on'
bind 'set skip-completed-text on'
# Use completion on sudo
complete -cf sudo

# ── 5. Terminal ────────────────────────────────────────────────
stty -ixon 2>/dev/null          # free Ctrl-S/Ctrl-Q for readline

# ── 6. Safety ──────────────────────────────────────────────────
set -o noclobber                # > won't silently clobber (use >|)
set -o notify                   # report bg job status immediately
set -o pipefail                 # pipeline fails if any cmd fails

# ── 7. Bash Completion ─────────────────────────────────────────
# Homebrew (macOS) — bash-completion@2
if [[ -r /opt/homebrew/etc/profile.d/bash_completion.sh ]]; then
  source /opt/homebrew/etc/profile.d/bash_completion.sh
fi
# Linux system-wide
if [[ -r /usr/share/bash-completion/bash_completion ]]; then
  source /usr/share/bash-completion/bash_completion
fi

# ── 8. Prompt ──────────────────────────────────────────────────
__prompt_cmd() {
  local rts=$?
  local green='\[\e[1;32m\]' red='\[\e[1;31m\]'
  local gray='\[\e[1;30m\]' fg_green='\[\e[0;32m\]' fg_red='\[\e[0;31m\]'
  local reset='\[\e[0m\]'

  PS1="${green}\u\[\e[1;37m\]@${red}\H ${gray}>"
  if (( rts == 0 )); then
    PS1+="${fg_green}>${green}>${reset} "
  else
    PS1+="${fg_red}>${red}>${reset} "
  fi
}
PROMPT_COMMAND='__prompt_cmd'

# Terminal title (xterm / rxvt)
case "${TERM}" in
  xterm*|rxvt*)
    PROMPT_COMMAND+='; printf "\e]0;%s@%s: %s\a" "${USER}" "${HOSTNAME}" "${PWD/${HOME}/\~}"'
    ;;
esac

# ── 10. Environment ─────────────────────────────────────────────
for envfile in ~/.rc/sh.d/S[0-9][0-9]*[^~]; do
  [[ -f "${envfile}" ]] && source "${envfile}"
done