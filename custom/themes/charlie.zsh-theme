# Reference
# Powerline Font    https://github.com/powerline/fonts
#                   []     $'\ue0a0'     U+E0A0
# Font Awesome      https://github.com/FortAwesome/Font-Awesome
# Prompt Sequences  http://zsh.sourceforge.net/Doc/Release/Prompt-Expansion.html

# Goals
# The aim of this theme is to only show you *relevant* information. Like most
# prompts, it will only show git information when in a git working directory.
# However, it goes a step further: everything from the current user and
# hostname to whether the last call exited with an error to whether background
# jobs are running in this shell will all be displayed automatically when
# appropriate.

# Most terminals supported colours
# black  red  green  yellow  blue  magenta  cyan  white  default
# http://zsh.sourceforge.net/Doc/Release/Zsh-Line-Editor.html#Character-Highlighting

CURRENT_BG='NONE'
HIGHTLIGHT_PROMPT='true'

() {
  local LC_ALL="" LC_CTYPE="en_US.UTF-8"
  # https://unicode-table.com/en/2718/
  UC_CMD_ERROR="%{%F{red}%}✘"     # U+2718
  # https://unicode-table.com/en/2621/
  UC_ROOR_USER="%{%F{yellow}%}☡"  # U+2621
  # https://unicode-table.com/cn/2699/
  UC_HAS_JOBS="%{%F{cyan}%}⚙"     # U+2699
  # https://unicode-table.com/en/27A4/
  UC_SEPARATOR="➤"                # U+27A4
  # https://unicode-table.com/cn/26D5/
  UC_BRANCH="⛕"                   # U+26D5
  # https://unicode-table.com/cn/blocks/private-use-area/
  #UC_BRANCH=""                  # U+E0A0
  #
  UC_HAS_STAGED="✚"
  #
  UC_HAS_UNSTAGED="±"
}

# Utility functions to make it easy and re-usable to draw segmented prompts.
#
# Takes two arguments, background and foreground.
# Both can be omitted, rendering default background/foreground.
prompt_msg() {
  local bg fg
  [[ -n $1 ]] && bg="%K{$1}" || bg="%k"
  [[ -n $2 ]] && fg="%F{$2}" || fg="%f"
  if [[ $CURRENT_BG != 'NONE' && $1 != $CURRENT_BG ]]; then
    echo -n "%{$bg%F{$CURRENT_BG}%}%{$fg%}"
  else
    echo -n "%{$bg%}%{$fg%}"
  fi
  CURRENT_BG=$1
  [[ -n $3 ]] && echo -n $3
}

# End the prompt, closing any open segments
prompt_end() {
  if [[ -n $CURRENT_BG ]]; then
    echo -n "%{%k%F{$CURRENT_BG}%}"
  else
    echo -n "%{%k%}"
  fi
  echo -n "%{%f%}"
  CURRENT_BG=''
}

# Git branch/detached head, dirty status
prompt_git() {
  (( $+commands[git] )) || return

  if [[ "$(git config --get oh-my-zsh.hide-status 2>/dev/null)" = 1 ]]; then
    return
  fi

  if [[ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" = "true" ]]; then
    local mode
    local repo_path=$(git rev-parse --git-dir 2>/dev/null)
    if [[ -e "${repo_path}/BISECT_LOG" ]]; then
      mode=" <B>"
    elif [[ -e "${repo_path}/MERGE_HEAD" ]]; then
      mode=" >M<"
    elif [[ -e "${repo_path}/rebase" || -e "${repo_path}/rebase-apply" || -e "${repo_path}/rebase-merge" || -e "${repo_path}/../.dotest" ]]; then
      mode=" >R>"
    fi

    setopt promptsubst
    autoload -Uz vcs_info
    # https://git-scm.com/book/en/v2/Appendix-A%3A-Git-in-Other-Environments-Git-in-Zsh
    # http://zsh.sourceforge.net/Doc/Release/User-Contributions.html#Version-Control-Information
    # http://zsh.sourceforge.net/Doc/Release/User-Contributions.html#vcs_005finfo-Configuration

    zstyle ':vcs_info:*' enable git
    zstyle ':vcs_info:*' get-revision true
    zstyle ':vcs_info:*' check-for-changes true
    zstyle ':vcs_info:*' stagedstr "${UC_HAS_STAGED}"
    zstyle ':vcs_info:*' unstagedstr "${UC_HAS_UNSTAGED}"
    zstyle ':vcs_info:*' formats '%u%c'
    zstyle ':vcs_info:*' actionformats '%u%c'
    vcs_info

    local used_color
    local dirty=$(parse_git_dirty)
    if [[ -n $dirty ]]; then
      used_color='yellow'
    else
      used_color='green'
    fi
    
    local ref=$(git symbolic-ref HEAD 2> /dev/null) || ref="➦ $(git rev-parse --short HEAD 2> /dev/null)"
    
    if [[ "$HIGHTLIGHT_PROMPT" = "true" ]]; then
      prompt_msg green black " ${UC_BRANCH} "
      prompt_msg ${used_color} black "${ref/refs\/heads\/}"
      prompt_msg red black "${vcs_info_msg_0_%%}${mode}"
    else
      prompt_msg black default " %{$fg[green]%}${UC_BRANCH} "
      prompt_msg black black "%{$fg[${used_color}]%}${ref/refs\/heads\/}"
      prompt_msg black black "%{$fg[red]%}${vcs_info_msg_0_%%}${mode}"
    fi
  fi
}

# Current Working Directory
prompt_cwd() {
  #local _CWDIR='%~'
  local _CWDIR=$(basename $PWD)
  [[ $_CWDIR = "$USER" ]] && _CWDIR='~'
  if [[ "$HIGHTLIGHT_PROMPT" = "true" ]]; then
    prompt_msg blue black "$_CWDIR"
  else
    prompt_msg black default "%{$fg[blue]%}$_CWDIR"
  fi
}

# User@HostName (who am I and where am I)
prompt_userhost() {
  if [[ "$USER" != "$DEFAULT_USER" || -n "$SSH_CLIENT" ]]; then
    if [[ "$HIGHTLIGHT_PROMPT" = "true" ]]; then
      prompt_msg magenta  black "%n"
      prompt_msg white    black "@"
      prompt_msg green    black "%m"
      prompt_msg yellow   black "${UC_SEPARATOR}"
    else
      prompt_msg black default "%{$fg[magenta]%}%n"
      prompt_msg black default "%{$fg[white]%}@"
      prompt_msg black default "%{$fg[green]%}%m"
      prompt_msg black default "%{$fg[yellow]%}${UC_SEPARATOR}%{$reset_color%}"
    fi
  fi
}

# Status:
# - am I root
# - was there an error
# - are there background jobs?
prompt_status() {
  local -a symbols
  #symbols+="${}"

  [[ $RETVAL -ne 0 ]] && symbols+="${UC_CMD_ERROR}"
  [[ $UID -eq 0 ]] && symbols+="${UC_ROOR_USER}"
  [[ $(jobs -l | wc -l) -gt 0 ]] && symbols+="${UC_HAS_JOBS}"

  [[ -n "$symbols" ]] && prompt_msg black default "$symbols"
}

# Main Prompt
build_prompt() {
  RETVAL=$?
  prompt_status
  prompt_userhost
  prompt_cwd
  prompt_git
  prompt_end
}

PROMPT='%{%f%b%k%}$(build_prompt) '
