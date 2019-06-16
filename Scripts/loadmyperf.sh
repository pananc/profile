function myperfinit()
{
  # Stop mysqld if needed.
  mysqlstop

  # Init a database.
  mysqlinit $*

  # Start mysqld.
  mysqlstart

  # Wait until mysqld can be connected.
  while : ; do
    mysqlshowme > /dev/null 2>&1
    if [ $? -ne 0 ]; then
      printf "."
      sleep 1
    else
      printf "\n"
      break
    fi
  done

  # Create database test.
  mysql --defaults-file=$MYSQL_CONFIG --user=root -e "create database test;" mysql

  # Prepare the database.
  if [ ! -d $HOME/sysbench-0.5/sysbench ]; then
    echo "Unable to locate the directory $HOME/sysbench-0.5/sysbench"
        return
  fi
  cd $HOME/sysbench-0.5/sysbench
  mysqlprepare
  cd -

  # Stop the database.
  mysqlstop

  # Backup the database.
  MYSQL_DATADIR=$(cat $CMDDIR/mysql.cfg | awk '{print $1}')
  MYSQL_BASENAME=$(basename $MYSQL_DATADIR)
  MYSQL_DIRNAME=$(dirname $MYSQL_DATADIR)
  cd $MYSQL_DIRNAME
  rm -f ${MYSQL_BASENAME}.tar.gz
  tar czf ${MYSQL_BASENAME}.tar.gz ./${MYSQL_BASENAME}
  cd -
  MYSQL_LOGDIR=$(cat $CMDDIR/mysql.cfg | awk '{print $2}')
  MYSQL_BASENAME=$(basename $MYSQL_LOGDIR)
  MYSQL_DIRNAME=$(dirname $MYSQL_LOGDIR)
  cd $MYSQL_DIRNAME
  rm -f ${MYSQL_BASENAME}.tar.gz
  tar czf ${MYSQL_BASENAME}.tar.gz ./${MYSQL_BASENAME}
  cd -

  # Start the database again.
  mysqlstart
}

function myperfrestore()
{
  if [ ! -f $CMDDIR/mysql.cfg ]; then
    echo "Unable to find $CMDDIR/mysql.cfg, run myperfinit <basedir> first"
        return
  fi

  MYSQL_DATADIR=$(cat $CMDDIR/mysql.cfg | awk '{print $1}')
  if [ ! -d $MYSQL_DATADIR/mysql ]; then
    echo "Data directory $MYSQL_DATADIR is not initialized yet"
    return
  fi

  # Stop the database.
  mysqlstop

  # Restore the database.
  MYSQL_DATADIR=$(cat $CMDDIR/mysql.cfg | awk '{print $1}')
  MYSQL_BASENAME=$(basename $MYSQL_DATADIR)
  MYSQL_DIRNAME=$(dirname $MYSQL_DATADIR)
  cd $MYSQL_DIRNAME
  if [ -f ${MYSQL_BASENAME}.tar.gz ]; then
    rm -rf ./${MYSQL_BASENAME}
    tar zxf ${MYSQL_BASENAME}.tar.gz
  fi
  cd -
  MYSQL_LOGDIR=$(cat $CMDDIR/mysql.cfg | awk '{print $2}')
  MYSQL_BASENAME=$(basename $MYSQL_LOGDIR)
  MYSQL_DIRNAME=$(dirname $MYSQL_LOGDIR)
  cd $MYSQL_DIRNAME
  if [ -f ${MYSQL_BASENAME}.tar.gz ]; then
    rm -rf ./${MYSQL_BASENAME}
    tar zxf ${MYSQL_BASENAME}.tar.gz
  fi
  cd -

  # Start the database.
  mysqlstart
}

function myperfrunread()
{
  # Stop mysqld.
  mysqlstop

  # Start mysqld.
  mysqlstart

  while : ; do
    mysqlshowme > /dev/null 2>&1
        if [ $? -ne 0 ]; then
      printf "."
      sleep 1
    else
      printf "\n"
      break
    fi
  done

  if [ ! -d $HOME/sysbench-0.5/sysbench ]; then
    echo "Unable to locate the directory $HOME/sysbench-0.5/sysbench"
    return
  fi

  DURATION=$1
  CONCURRENCY=$2
  if [ -z $DURATION ]; then
    DURATION=600
  fi
  if [ -z $CONCURRENCY ]; then
    CONCURRENCY=100
  fi

  # Start recording the performance data.
  perfrecord mysqld $DURATION &

  # Run performance test.
  cd $HOME/sysbench-0.5/sysbench
  mysqlrunread $DURATION $CONCURRENCY | tee $REPORTDIR/myperf_read.result
  cd -

  # Wait until perf exited.
  while : ; do
    pidof perf > /dev/null 2>&1
    if [ $? -eq 0 ]; then
      printf "."
      sleep 1
    else
      printf "\n"
      break
    fi
  done

  # Generate the performance report.
  perfreport myperf_read

  # Gather the report files.
  cd $REPORTDIR
  CSVFILE=$(ls -t myperf_read*.csv | head -n 1)
  FILENAME="${CSVFILE%.*}"
  mkdir $FILENAME
  mv $REPORTDIR/myperf_read.result ${FILENAME}
  mv ${FILENAME}.csv ${FILENAME}/
  mv ${FILENAME}_*.report ${FILENAME}/
  cd -
}

function myperfrunwrite()
{
  # Stop mysqld.
  mysqlstop

  # Start mysqld.
  mysqlstart

  while : ; do
    mysqlshowme > /dev/null 2>&1
    if [ $? -ne 0 ]; then
      printf "."
      sleep 1
    else
      printf "\n"
      break
    fi
  done

  if [ ! -d $HOME/sysbench-0.5/sysbench ]; then
    echo "Unable to locate the directory $HOME/sysbench-0.5/sysbench"
    return
  fi

  DURATION=$1
  CONCURRENCY=$2
  if [ -z $DURATION ]; then
    DURATION=600
  fi
  if [ -z $CONCURRENCY ]; then
    CONCURRENCY=100
  fi
  
  # Start recording the performance data.
  perfrecord mysqld $DURATION &

  # Run performance test.
  cd $HOME/sysbench-0.5/sysbench
  mysqlrunwrite $DURATION $CONCURRENCY | tee $REPORTDIR/myperf_write.result
  cd -

  # Wait until perf exited.
  while : ; do
    pidof perf > /dev/null 2>&1
    if [ $? -eq 0 ]; then
      printf "."
      sleep 1
    else
      printf "\n"
      break
    fi
  done

  # Generate the performance report.
  perfreport myperf_write

  # Gather the report files.
  cd $REPORTDIR
  CSVFILE=$(ls -t myperf_write*.csv | head -n 1)
  FILENAME="${CSVFILE%.*}"
  mkdir $FILENAME
  mv $REPORTDIR/myperf_write.result ${FILENAME}
  mv ${FILENAME}.csv ${FILENAME}/
  mv ${FILENAME}_*.report ${FILENAME}/
  cd -
}

function myperfrunpurewrite()
{
  # Stop mysqld.
  mysqlstop

  # Start mysqld.
  mysqlstart

  while : ; do
    mysqlshowme > /dev/null 2>&1
    if [ $? -ne 0 ]; then
      printf "."
      sleep 1
    else
      printf "\n"
      break
    fi
  done

  if [ ! -d $HOME/sysbench-0.5/sysbench ]; then
    echo "Unable to locate the directory $HOME/sysbench-0.5/sysbench"
    return
  fi

  DURATION=$1
  CONCURRENCY=$2
  if [ -z $DURATION ]; then
    DURATION=600
  fi
  if [ -z $CONCURRENCY ]; then
    CONCURRENCY=100
  fi
  
  # Start recording the performance data.
  perfrecord mysqld $DURATION &

  # Run performance test.
  cd $HOME/sysbench-0.5/sysbench
  mysqlrunpurewrite $DURATION $CONCURRENCY | tee $REPORTDIR/myperf_purewrite.result
  cd -

  # Wait until perf exited.
  while : ; do
    pidof perf > /dev/null 2>&1
    if [ $? -eq 0 ]; then
      printf "."
      sleep 1
    else
      printf "\n"
      break
    fi
  done

  # Generate the performance report.
  perfreport myperf_purewrite

  # Gather the report files.
  cd $REPORTDIR
  CSVFILE=$(ls -t myperf_purewrite*.csv | head -n 1)
  FILENAME="${CSVFILE%.*}"
  mkdir $FILENAME
  mv $REPORTDIR/myperf_purewrite.result ${FILENAME}
  mv ${FILENAME}.csv ${FILENAME}/
  mv ${FILENAME}_*.report ${FILENAME}/
  cd -
}
