IOTOP_ROOT=$HOME/iotop-0.6

# Note: Need install iotop & python-curses
# 1. tar zxvf ~/Utils/packages/iotop-0.6.tar.gz
# 2. zypper install python-curses

function iotopprocess()
{
  WHO=$1
  if [ -z $WHO ]; then
    WHO=$USER
  fi
  sudo $IOTOP_ROOT/iotop.py -a -o -P -d 3 -u $WHO
}

function iotopthread()
{
  WHO=$1
  if [ -z $WHO ]; then
    WHO=$USER
  fi
  sudo $IOTOP_ROOT/iotop.py -a -o -d 3 -u $WHO
}
