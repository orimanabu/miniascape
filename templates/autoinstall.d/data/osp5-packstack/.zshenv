#

export PATH=/opt/local/bin:/opt/local/sbin:/usr/local/bin:/usr/local/sbin:$PATH:/usr/pkg/bin:/usr/pkg/sbin
#export PATH=/opt/brew/bin:/opt/brew/sbin:/usr/local/bin:/usr/local/sbin:$PATH:/usr/pkg/bin:/usr/pkg/sbin
#export PERL5LIB=$HOME/opt/lib/perl5/site_perl:$HOME/opt/lib/perl5/5.8.9/site_perl

export EDITOR=vim

export MODULEBUILDRC="/Users/ori/opt/.modulebuildrc"
export PERL_MM_OPT="INSTALL_BASE=/Users/ori/opt"
export PERL5LIB="/Users/ori/opt/lib/perl5/darwin-2level:/Users/ori/opt/lib/perl5"
export ORI_PERL_VERSION=$(perl -e '$] =~ /(\d+)\.(\d{3})(\d{3})/; print join(".", $1, int($2), int($3)), "\n"')
export PATH="/Users/ori/opt/bin:$PATH"

export PYTHONSTARTUP=${HOME}/.pythonstartup
