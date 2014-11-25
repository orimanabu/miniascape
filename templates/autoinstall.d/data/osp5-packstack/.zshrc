#!/bin/zsh

###
### Prompt
###
#PROMPT="%{[32m%}$LOGNAME%b%{[m%}[%h]%% "
#RPROMPT="[%{[33m%}%(3~,%-2~/.../%2~,%~)%{[m%}]"
PROMPT="$LOGNAME@%{[32m%}%B%m%b %# "
PROMPT=$(print "$LOGNAME@%B%{\e[32m%}%m:%(5~,%-2~/.../%2~,%~)%{\e[33m%}%b %# ")

if [ "$TERM" = "screen" ]; then
	local -a shorthost

	echo $TERMCAP | grep -q -i screen
	if [ $? -eq 0 ]; then
		shorthost=""
	else
		shorthost="${HOST%%.*}:"
	fi

	echo -ne "\ek$shorthost\e\\"

	preexec() {
		echo -ne "\ek${shorthost}($1)\e\\"
		echo -ne "\e_`dirs`\e\\"
	}

	precmd() {
		echo -ne "\ek${shorthost}$(basename $(pwd))\e\\"

		psvar=()
		LANG=en_US.UTF-8 vcs_info
		[[ -n "$vcs_info_msg_0_" ]] && psvar[1]="$vcs_info_msg_0_"
	}
fi

autoload -Uz vcs_info
zstyle ':vcs_info:*' formats '(%s:%b)'
zstyle ':vcs_info:*' actionformats '(%s:%b:%a)'
#precmd () {
#    psvar=()
#    LANG=en_US.UTF-8 vcs_info
#    [[ -n "$vcs_info_msg_0_" ]] && psvar[1]="$vcs_info_msg_0_"
#}
RPROMPT="%1(v|%F{green}%1v%f|)"

###
### Key Bindings
###
bindkey -e

autoload -U select-word-style
select-word-style bash

autoload history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey "^P" history-beginning-search-backward-end
bindkey "^N" history-beginning-search-forward-end
bindkey "\\ep" history-beginning-search-backward-end
bindkey "\\en" history-beginning-search-forward-end

bindkey "^[f" emacs-forward-word
bindkey "^[b" emacs-backward-word
export WORDCHARS=""

###
### Completion
###
autoload -U compinit
compinit
setopt complete_aliases
#zstyle ':completion:*:default' menu select true
fpath=(/opt/brew/share/zsh-completions $fpath)

###
### History
###
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt hist_ignore_dups # ignore duplication command history list
setopt share_history # share command history data
setopt append_history
setopt inc_append_history


###
### Options
###
setopt auto_list
unsetopt auto_menu
setopt auto_param_keys
setopt auto_param_slash
setopt NO_beep
setopt list_types
setopt magic_equal_subst
setopt mark_dirs
#setopt pushd_ignore_dups
setopt transient_rprompt
#setopt auto_pushd
setopt noautoremoveslash

###
### Aliases
###
alias rmbak='rm -f *~'
alias screensaver='open /System/Library/Frameworks/ScreenSaver.framework/Resources/ScreenSaverEngine.app'
alias systemsuspend='/usr/bin/pmset sleepnow'
alias kvim=/Applications/MacVim.app/Contents/MacOS/vim
alias mvim=/Applications/MacVim.app/Contents/MacOS/mvim
case "${OSTYPE}" in
freebsd*|darwin*)
  alias ls="ls -F -G -w -v"
  ;;
linux*)
  alias ls="ls --color"
  ;;
esac
alias disasm='gobjdump -CSIw -M intel'

###
### Functions
###
function wman() {
   url="man -w ${1} | sed 's#.*\(${1}.\)\([[:digit:]]\).*\$#http://developer.apple.com/documentation/Darwin/Reference/ManPages/man\2/\1\2.html#'"
   open `eval $url`
}

###
### Local Settings
###
[ -f ~/.zshrc.local ] && source ~/.zshrc.local
