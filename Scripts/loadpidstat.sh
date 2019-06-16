pidstatio()
{
  PROGNAME=$1
  if [ -z $PROGNAME ]; then
    pidstat -d 3
  else
    pidstat -p `pidof -s $PROGNAME` -dt 3 | tee $REPORTDIR/${PROGNAME}_pidstat_io.report
  fi
}

pidstatmem()
{
  PROGNAME=$1
  if [ -z $PROGNAME ]; then
    pidstat -r 3
  else
    pidstat -p `pidof -s $PROGNAME` -rt 3 | tee $REPORTDIR/${PROGNAME}_pidstat_mem.report
  fi
}

pidstatcpu()
{
  PROGNAME=$1
  if [ -z $PROGNAME ]; then
    pidstat -u 3
  else
    pidstat -p `pidof -s $PROGNAME` -ut 3 | tee $REPORTDIR/${PROGNAME}_pidstat_cpu.report
  fi
}

pidstattask()
{
  PROGNAME=$1
  if [ -z $PROGNAME ]; then
    pidstat -w 3
  else
    pidstat -p `pidof -s $PROGNAME` -wt 3 | tee $REPORTDIR/${PROGNAME}_pidstat_task.report
  fi
}
