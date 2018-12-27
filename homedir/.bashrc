# Source global definitions
if [ -f /etc/bashrc ]; then
  . /etc/bashrc
fi

PATH=$PATH:~/bin 

source ~/.git-completion.bash
source ~/.git-prompt.bash

MAGENTA="\[\033[0;35m\]"  
YELLOW="\[\033[0;33m\]"
BLUE="\[\033[34m\]" 
LIGHT_GRAY="\[\033[0;37m\]"  
CYAN="\[\033[0;36m\]"  
GREEN="\[\033[0;32m\]" 
GIT_PS1_SHOWDIRTYSTATE=true  
export LS_OPTIONS='--color=auto'
export LSCOLORS=gxfxbEaEBxxEhEhBaDaCaD
  
export PS1=$LIGHT_GRAY"[\u@\h"'$(  
    if [[ $(__git_ps1) =~ \*\)$ ]] 
    # a file has been modified but not added
    then echo "'$YELLOW'"$(__git_ps1 " (%s)")  
    elif [[ $(__git_ps1) =~ \+\)$ ]]  
    # a file has been added, but not commited  
    then echo "'$MAGENTA'"$(__git_ps1 " (%s)") 
    # the state is clean, changes are commited 
    else echo "'$CYAN'"$(__git_ps1 " (%s)") 
    fi)'$YELLOW" \w"$LIGHT_GRAY" ]$ " 
  
alias ll='ls -lah'

#-- fix ssh agent for tmux sessions
fixssh() {
  for key in SSH_AUTH_SOCK SSH_CONNECTION SSH_CLIENT; do
    if (tmux show-environment | grep "^${key}" > /dev/null); then
      value=`tmux show-environment | grep "^${key}" | sed -e "s/^[A-Z_]*=//"`
      export ${key}="${value}"
    fi
  done
}
