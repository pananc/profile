# Attach to a session.
function attach()
{
  screen -r -d session$1
}

function mycat()
{
  FILENAME=$1
  if [ -z $1 ]; then
    echo "Don't know the file to be opened"
  else
    # The first file found.
    FILEDIR=`find $PWD -name $FILENAME | awk 'NR==1 {print $1}'`
    if [ -z $FILEDIR ]; then
      echo "Can't find the file $FILENAME"
    else
      cat $FILEDIR
    fi
  fi
}

function myvi()
{
  FILENAME=$1
  if [ -z $1 ]; then
    echo "Don't know the file to be opened"
  else
    # The first file found.
    FILEDIR=`find $PWD -name $FILENAME | awk 'NR==1 {print $1}'`
    if [ -z $FILEDIR ]; then
      echo "Can't find the file $FILENAME"
    else
      vim $FILEDIR
    fi
  fi
}

function myrm()
{
  FILENAME=$1
  if [ -z $1 ]; then
    echo "Don't know the file to be deleted"
  else
    # The first file found.
    FILEDIR=`find $PWD -name $FILENAME | awk 'NR==1 {print $1}'`
    if [ -z $FILEDIR ]; then
      echo "Can't find the file $FILENAME"
    else
      rm -f $FILEDIR
    fi
  fi
}

function mywatch()
{
  FILENAME=$1
  if [ -z $FILENAME ]; then
    echo "Usage: mywatch <filename>"
    return
  fi

  watch -tdn3 cat $FILENAME
}

function myclearcache()
{
  # Writing to this file causes the kernel to drop clean caches, dentries and inodes from memory, causing that memory to become free.
  #
  # To free pagecache, use echo 1 > /proc/sys/vm/drop_caches; to free dentries and inodes, use echo 2 > /proc/sys/vm/drop_caches; to free pagecache, dentries and inodes, use echo 3 > /proc/sys/vm/drop_caches.
  #
  # Because this is a non-destructive operation and dirty objects are not freeable, the user should run sync(8) first.
  
  # Clear pagecache, dentries and inodes
  echo 3 > /proc/sys/vm/drop_caches
  # Restore the value to default
  echo 0 > /proc/sys/vm/drop_caches
}

function myssh()
{
  IFS=$'\n'
  
  SSH_HOSTS=$(cat $HOME/Scripts/host.list | awk '{print $1}')
  for SSH_HOST in $SSH_HOSTS
  do
    ssh $SSH_HOST ls
  done
  IFS=$' '
}

function showdisk()
{
  du -h --max-depth=1 ./
}

function showio()
{
  iostat -xmd -p ALL 3
}

function showcpu()
{
  mpstat -P ALL 3
}

function showvm()
{
  vmstat 3
}

function showmem()
{
  if [ -z $1 ]; then
    echo "Usage: showmem <progname>"
    return
  fi

  pmap `pidof -s $1`
}

function showfiles()
{
  if [ -z $1 ]; then
    echo "Usage: showfiles <progname>"
    return
  fi

  lsof -p `pidof -s $1`
}

function showhd()
{
  DEVICE=$1
  if [ -z $DEVICE ]; then
    DEVICE=/dev/sda1
  fi

  sudo /sbin/hdparm -tT $DEVICE
  sudo /sbin/hdparm -tT --direct $DEVICE
}

function showfree()
{
  free -m
}

function showthread()
{
  if [ -z $1 ]; then
    top -H
  else
    top -H -p `pidof -s $1`
  fi
}

function showprocess()
{
  if [ -z $1 ]; then
    ps -u $USER ef
  else
    ps -u $1 ef
  fi
}

function showstack()
{
  # Ref to poormansprofiler (https://poormansprofiler.org/)
  PROGNAME=$1
  if [ -z "$PROGNAME" ]; then
    echo "Usage: showstack <progname> [<nsamples> <interval>]"
    return
  fi

  PROGPID=$(pgrep -u $USER $PROGNAME)
  if [ -z "$PROGPID" ]; then
    echo "$PROGNAME is not running"
    return
  fi
  NSAMPLES=$2
  if [ -z "$NSAMPLES" ]; then
    NSAMPLES=1
  fi
  INTERVAL=$3
  if [ -z "$INTERVAL" ]; then
    INTERVAL=60
  fi

  IFS=$'\n'
  for x in $(seq $NSAMPLES)
  do
    echo "----------------------------${x}----------------------------"
    # gdb -ex "set pagination 0" -ex "thread apply all bt" -batch -p $PROGPID
    gstack $PROGPID | \
    awk '
      BEGIN { s = ""; } 
      /^Thread/ { print s; s = ""; } 
      /^\#/ { if (s != "" ) { s = s "," $4} else { s = $4 } } 
      END { print s }' | \
    sort | uniq -c | sort -r -n -k 1,1
    sleep $INTERVAL
  done
  IFS=$' '
}

function showstack2()
{
  PROGNAME=$1
  if [ -z "$PROGNAME" ]; then
    echo "Usage: showstack2 <progname> [<nsamples> <interval>]"
    return
  fi

  PROGPID=$(pgrep -u $USER $PROGNAME)
  if [ -z "$PROGPID" ]; then
    echo "$PROGNAME is not running"
    return
  fi
  NSAMPLES=$2
  if [ -z "$NSAMPLES" ]; then
    NSAMPLES=1
  fi
  INTERVAL=$3
  if [ -z "$INTERVAL" ]; then
    INTERVAL=60
  fi

  IFS=$'\n'
  rm -f $REPORTDIR/${PROGNAME}.summary
  for x in $(seq $NSAMPLES)
  do
    echo "----------------------------${x}----------------------------" | tee -a $REPORTDIR/${PROGNAME}.summary
    gstack $PROGPID > $REPORTDIR/${PROGNAME}.stack
    parsegstack2 $REPORTDIR/${PROGNAME}.stack | tee -a $REPORTDIR/${PROGNAME}.summary
    rm -f $REPORTDIR/${PROGNAME}.stack
    sleep $INTERVAL
  done
  IFS=$' '
}

function showall()
{
  dstat --cpu --net -N total --disk --disk-util --mem --lock --integer --load --swap
}

function svnupdate()
{
  LC_ALL_PREV=$LC_ALL
  export LC_ALL=zh_CN.utf8
  if [ -z $1 ]; then
    svn update
  else
    svn update -r $1
  fi
  export LC_ALL=$LC_ALL_PREV
}

function svnrevert()
{
  LC_ALL_PREV=$LC_ALL
  export LC_ALL=zh_CN.utf8
  svn revert -R .
  export LC_ALL=$LC_ALL_PREV
}
