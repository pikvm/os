#
# ~/.bash_profile
#

export XAUTHORITY=/tmp/.Xauthority-root

[[ -f ~/.bashrc ]] && . ~/.bashrc

if [[ -z $DISPLAY ]] && [[ $(tty) = /dev/tty1 ]]; then
	exec startx
fi
