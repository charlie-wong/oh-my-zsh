# In order for this theme to render correctly, you should 
# install [Powerline Font](https://github.com/powerline/fonts)
# []     $'\ue0a0'     U+E0A0

# ZSH Docs
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
  # https://unicode-table.com/en/27A4/
  UC_HAS_STAGED="✚"               # 
  # https://unicode-table.com/en/27A4/
  UC_HAS_UNSTAGED="±"             # 

  # https://unicode-table.com/cn/26D5/
  #UC_BRANCH="⛕"                  # U+26D5
  # https://unicode-table.com/cn/blocks/private-use-area/
  UC_BRANCH=""                   # U+E0A0
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
    setopt promptsubst
    autoload -Uz vcs_info
    # http://zsh.sourceforge.net/Doc/Release/Prompt-Expansion.html
    # http://zsh.sourceforge.net/Doc/Release/Zsh-Line-Editor.html#Character-Highlighting
    # https://git-scm.com/book/en/v2/Appendix-A%3A-Git-in-Other-Environments-Git-in-Zsh
    # http://zsh.sourceforge.net/Doc/Release/User-Contributions.html#Version-Control-Information
    # %n  $USERNAME
    # %F{red}   Foreground colour red
    # %K{red}   Background colour red
    #           black/0    red/1   green/2  yellow/3   blue/4
    #           magenta/5  cyan/6  white/7  default/8
    # %s        The VCS in use, like git/hg/svn/...
    # %b        Information about the current branch
    # %c        The value of stagedstr if staged changes in the repository
    # %u        The value of unstagedstr if unstaged changes in the repository
    # %a        Identifier describes the action, only valid for actionformats

    local _BC_
    local dirty=$(parse_git_dirty) # call OH-MY-ZSH function
    if [[ -n $dirty ]]; then
      _BC_='yellow'
    else
      _BC_='green'
    fi

    # echo -n "[%K{black}%F{0}0 %F{1}1 %F{2}2 %F{3}3 %F{4}4"
    # echo -n " %K{black}%F{5}5 %F{6}6 %F{7}7 %F{8}8 %F{9}9]"
    
    zstyle ':vcs_info:git:*' enable git
    zstyle ':vcs_info:git:*' check-for-changes true
    zstyle ':vcs_info:git:*' stagedstr "${UC_HAS_STAGED}" # for %c
    zstyle ':vcs_info:git:*' unstagedstr "${UC_HAS_UNSTAGED}" # for %u

    if [[ "$HIGHTLIGHT_PROMPT" = "true" ]]; then
      zstyle ':vcs_info:git:*' formats "%K{3}${UC_SEPARATOR}%K{5}%s%K{3}${UC_BRANCH}%K{${_BC_}}%b%K{1}%u%c"
      zstyle ':vcs_info:git:*' actionformats "%K{3}${UC_SEPARATOR}%K{5}%s%K{3}${UC_BRANCH}%K{${_BC_}}%b[%a]%K{1}%u%c"
      vcs_info # run it now
      echo -n "${vcs_info_msg_0_}"
    else
      zstyle ':vcs_info:git:*' formats "%F{3}${UC_SEPARATOR}%F{5}%s%F{3}${UC_BRANCH}%F{${_BC_}}%b%F{1}%u%c"
      zstyle ':vcs_info:git:*' actionformats "%K{3}${UC_SEPARATOR}%K{5}%s%K{3}${UC_BRANCH}%F{${_BC_}}%b[%a]%K{1}%u%c"
      vcs_info # run it now
      echo -n "${vcs_info_msg_0_}"
    fi
  fi
}

# Current Working Directory
prompt_cwd() {
  local _CWDIR='%~'
  #local _CWDIR=$(basename $PWD)
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
      prompt_msg magenta black "%n"
      prompt_msg yellow  black "@"
      prompt_msg cyan    black "%m"
      prompt_msg yellow  black "${UC_SEPARATOR}"
    else
      prompt_msg black default "%{$fg[magenta]%}%n"
      prompt_msg black default "%{$fg[yellow]%}@"
      prompt_msg black default "%{$fg[cyan]%}%m"
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
  local _beg_time=$(date +%s%N) # nanosecond
  RETVAL=$?
  prompt_status
  prompt_userhost
  prompt_cwd
  prompt_git
  prompt_end
  local _end_time=$(date +%s%N) # nanosecond
  echo "EST=$[(_end_time - _beg_time)/1000000]ms"
}

PROMPT='%{%f%b%k%}$(build_prompt) '
