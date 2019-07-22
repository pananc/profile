# Sample .profile for SuSE Linux
# rewritten by Christian Steinruecken <cstein@suse.de>
#
# This file is read each time a login shell is started.
# All other interactive shells will only read .bashrc; this is particularly
# important for language settings, see below.

test -z "$PROFILEREAD" && . /etc/profile || true

# Most applications support several languages for their output.
# To make use of this feature, simply uncomment one of the lines below or
# add your own one (see /usr/share/locale/locale.alias for more codes)
# This overwrites the system default set in /etc/sysconfig/language
# in the variable RC_LANG.
#
#export LANG=de_DE.UTF-8        # uncomment this line for German output
#export LANG=fr_FR.UTF-8        # uncomment this line for French output
#export LANG=es_ES.UTF-8        # uncomment this line for Spanish output


# Some people don't like fortune. If you uncomment the following lines,
# you will have a fortune each time you log in ;-)

#if [ -x /usr/bin/fortune ] ; then
#    echo
#    /usr/bin/fortune
#    echo
#fi

# Set general environment variables
export DATADIR=$HOME
export LOGDIR=$HOME/Logs
export BACKUPDIR=$HOME/Backup
export ARCHIVEDIR=$HOME/Archive
export CMDDIR=$HOME/Command
export LIBDIR=$HOME/Library
export REPORTDIR=$HOME/Report

# Set DB related environment variables
export PGDATA=$DATADIR/pgdata
export CNDATA=$DATADIR/cndata
export CNDATA2=$DATADIR/cndata2
export DTDATA=$DATADIR/dtdata
export PGPORT=8888
export PNPORT=8887
export CNPORT=8886
export CNPORT2=8885
export DTPORT=8884
export REPLPORT=8883
export CLUSTER_MIN_DYNPORT=5000
export CLUSTER_MAX_DYNPORT=5200
export COCKROACHPORT=30000

# Set PATH
export PATH=$PATH:$HOME/postgres/bin
export PATH=$PATH:$HOME/Scripts
export PATH=$HOME/mysql/bin:$PATH
export PATH=$HOME/mysql/scripts:$PATH
export PATH=$HOME/mysql-cluster/bin:$PATH
export PATH=$HOME/mysql-cluster/scripts:$PATH
export PATH=$HOME/db/bin:$PATH
export PATH=$PATH:$HOME/sysbench/bin
export PATH=$PATH:$HOME/pt/bin
export PATH=$PATH:$HOME/oprofile/bin
export PATH=$HOME/gdb/bin:$PATH
export PATH=$HOME/cmake/bin:$PATH
export PATH=$HOME/unixODBC/bin:$PATH
export PATH=$PATH:$HOME/graphviz/bin
export PATH=$PATH:$HOME/inotify-tools/bin
export PATH=$PATH:$HOME/otp/bin
export PATH=$PATH:$HOME/llvm/bin
export PATH=$HOME/apache-maven-3.3.9/bin:$PATH
export PATH=$PATH:$HOME/stress-ng/bin
export PATH=$PATH:$HOME/sysstat/bin

# Set LD_LIBRARY_PATH
export LD_LIBRARY_PATH=$HOME/mysql/lib:$LD_LIBRARY_PATH:$HOME/mysql/lib/plugin
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$HOME/mysql-cluster/lib
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$HOME/unixODBC/lib
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$HOME/psqlODBC/lib
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$HOME/yaml/lib
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib

# Set ODBC
export ODBCINI=$HOME/unixODBC/etc/odbc.ini
export ODBCSYSINI=$HOME/unixODBC/etc

# Set GDB
export GDBHISTFILE=$HOME/.gdb_history

# Set GO
export PATH=$HOME/go/bin:$PATH
export PATH=$HOME/goproj/bin:$PATH
export GOROOT=$HOME/go
export GOPATH=$HOME/goproj

# Set aliases
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
alias grep='grep --color=auto'
alias ls='ls --color=auto'
alias ll="IFS=$' '; ls -la"
alias nload='$HOME/nload/bin/nload'
alias htop='$HOME/htop/bin/htop'

# Set git
if [ -f ~/.git-completion.bash ]; then
  . ~/.git-completion.bash
fi

# Turn on core dump
ulimit -c unlimited
ulimit -m unlimited
ulimit -v unlimited

# Set locale
export LC_ALL=C

# For wrong &apos;git log&apos; color display.
export LESS=-R

# Load self defined scripts.
. $HOME/Scripts/loadall.sh || true
