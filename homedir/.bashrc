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
function sshagent_findsockets {
  find /tmp -uid $(id -u) -type s -name agent.\* 2>/dev/null
}

function sshagent_testsocket {
  export SSH_AUTH_SOCK=$1

  ssh-add -l 2>&1 /dev/null
  if [[ $? -ne 0 ]] ; then
    echo "Socket $SSH_AUTH_SOCK is dead!  Deleting!"
    rm -f $SSH_AUTH_SOCK
  else
    return 0
  fi
  return 4
}

fixssh() {
  if [[ ! -x "$(which ssh-add)" ]]; then
    echo "ssh-add is not available; agent testing aborted"
    return 1
  fi

  for sshagent_potential_socket in $(sshagent_findsockets) ; do
    echo "Testing $sshagent_potential_socket"
    if [[ $(sshagent_testsocket $sshagent_potential_socket) ]]; then
      echo "Found ssh-agent $SSH_AUTH_SOCK"
      export SSH_AUTH_SOCK=$sshagent_potential_socket
      break
    fi
  done
}
