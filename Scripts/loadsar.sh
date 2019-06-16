sarcpu()
{
  TAG=$1
  TIMESTAMP=$(date +%Y_%m_%d_%H_%M_%S)
  if [ -z $TAG ]; then
    sar -u -o $REPORTDIR/sar_cpu_${TIMESTAMP}.stat 3
  else
    sar -u -o $REPORTDIR/${TAG}_sar_cpu_${TIMESTAMP}.stat 3
  fi
}

sarparsecpu()
{
  STATFILE=$1
  if [ -z $STATFILE ]; then
    echo "Usage: sarparsecpu <statfile>"
    return
  fi

  sar -u -f $STATFILE | tee sar_cpu.report
}

sarmem()
{
  TAG=$1
  TIMESTAMP=$(date +%Y_%m_%d_%H_%M_%S)
  if [ -z $TAG ]; then
    sar -r -R -o $REPORTDIR/sar_mem_${TIMESTAMP}.stat 3
  else
    sar -r -R -o $REPORTDIR/${TAG}_sar_mem_${TIMESTAMP}.stat 3
  fi
}

sarparsemem()
{
  STATFILE=$1
  if [ -z $STATFILE ]; then
    echo "Usage: sarparsemem <statfile>"
    return
  fi

  sar -r -R -f $STATFILE | tee sar_mem.report
}

sario()
{
  TAG=$1
  TIMESTAMP=$(date +%Y_%m_%d_%H_%M_%S)
  if [ -z $TAG ]; then
    sar -b -o $REPORTDIR/sar_io_${TIMESTAMP}.stat 3
  else
    sar -b -o $REPORTDIR/${TAG}_sar_io_${TIMESTAMP}.stat 3
  fi
}

sarparseio()
{
  STATFILE=$1
  if [ -z $STATFILE ]; then
    echo "Usage: sarparseio <statfile>"
    return
  fi

  sar -b -f $STATFILE | tee sar_io.report
}

sarpage()
{
  TAG=$1
  TIMESTAMP=$(date +%Y_%m_%d_%H_%M_%S)
  if [ -z $TAG ]; then
    sar -B -o $REPORTDIR/sar_page_${TIMESTAMP}.stat 3
  else
    sar -B -o $REPORTDIR/${TAG}_sar_page_${TIMESTAMP}.stat 3
  fi
}

sarparsepage()
{
  STATFILE=$1
  if [ -z $STATFILE ]; then
    echo "Usage: sarparsepage <statfile>"
    return
  fi

  sar -B -f $STATFILE | tee sar_page.report
}

sarblock()
{
  TAG=$1
  TIMESTAMP=$(date +%Y_%m_%d_%H_%M_%S)
  if [ -z $TAG ]; then
    sar -d -o $REPORTDIR/sar_block_${TIMESTAMP}.stat 3
  else
    sar -d -o $REPORTDIR/${TAG}_sar_block_${TIMESTAMP}.stat 3
  fi
}

sarparseblock()
{
  STATFILE=$1
  if [ -z $STATFILE ]; then
    echo "Usage: sarparseblock <statfile>"
    return
  fi

  sar -d -f $STATFILE | tee sar_block.report
}

sarnetwork()
{
  TAG=$1
  TIMESTAMP=$(date +%Y_%m_%d_%H_%M_%S)
  if [ -z $TAG ]; then
    sar -n ALL -o $REPORTDIR/sar_network_${TIMESTAMP}.stat 3
  else
    sar -n ALL -o $REPORTDIR/${TAG}_sar_network_${TIMESTAMP}.stat 3
  fi
}

sarparsenetwork()
{
  STATFILE=$1
  if [ -z $STATFILE ]; then
    echo "Usage: sarparsenetwork <statfile>"
    return
  fi

  sar -n ALL -f $STATFILE | tee sar_network.report
}

sarqueue()
{
  TAG=$1
  TIMESTAMP=$(date +%Y_%m_%d_%H_%M_%S)
  if [ -z $TAG ]; then
    sar -q -o $REPORTDIR/sar_queue_${TIMESTAMP}.stat 3
  else
    sar -q -o $REPORTDIR/${TAG}_sar_queue_${TIMESTAMP}.stat 3
  fi
}

sarparsequeue()
{
  STATFILE=$1
  if [ -z $STATFILE ]; then
    echo "Usage: sarparsequeue <statfile>"
    return
  fi

  sar -q -f $STATFILE | tee sar_queue.report
}

sarfile()
{
  TAG=$1
  TIMESTAMP=$(date +%Y_%m_%d_%H_%M_%S)
  if [ -z $TAG ]; then
    sar -v -o $REPORTDIR/sar_file_${TIMESTAMP}.stat 3
  else
    sar -v -o $REPORTDIR/${TAG}_sar_file_${TIMESTAMP}.stat 3
  fi
}

sarparsefile()
{
  STATFILE=$1
  if [ -z $STATFILE ]; then
    echo "Usage: sarparsefile <statfile>"
    return
  fi

  sar -v -f $STATFILE | tee sar_file.report
}

sartask()
{
  TAG=$1
  TIMESTAMP=$(date +%Y_%m_%d_%H_%M_%S)
  if [ -z $TAG ]; then
    sar -w -W -o $REPORTDIR/sar_task_${TIMESTAMP}.stat 3
  else
    sar -w -W -o $REPORTDIR/${TAG}_sar_task_${TIMESTAMP}.stat 3
  fi
}

sarparsetask()
{
  STATFILE=$1
  if [ -z $STATFILE ]; then
    echo "Usage: sarparsetask <statfile>"
    return
  fi

  sar -w -W -f $STATFILE | tee sar_task.report
}

sarswap()
{
  TAG=$1
  TIMESTAMP=$(date +%Y_%m_%d_%H_%M_%S)
  if [ -z $TAG ]; then
    sar -S -o $REPORTDIR/sar_swap_${TIMESTAMP}.stat 3
  else
    sar -S -o $REPORTDIR/${TAG}_sar_swap_${TIMESTAMP}.stat 3
  fi
}

sarparseswap()
{
  STATFILE=$1
  if [ -z $STATFILE ]; then
    echo "Usage: sarparseswap <statfile>"
    return
  fi

  sar -S -f $STATFILE | tee sar_swap.report
}

sarstrace()
{
  PROGNAME=$1
  if [ -z $PROGNAME ]; then
    echo "Usage: sarstrace <progname>"
    return
  fi

  strace -c -p `pidof -s $PROGNAME`
}

sargstack()
{
  PROGNAME=$1
  if [ -z $PROGNAME ]; then
    echo "Usage: sargstack <progname>"
    return
  fi

  PROGPID=$(pidof -s $PROGNAME)
  if [ -z "$PROGPID" ]; then
    echo "Can't find active process $PROGNAME"
        return
  fi
  gstack `pidof -s $PROGNAME` > $REPORTDIR/${PROGNAME}_${PROGPID}.stack
}
