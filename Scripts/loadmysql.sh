MYSQL_BASEDIR=$HOME/mysql
MYSQL_CONFIG=$HOME/my_test.cnf
MASTER_CONFIG=$HOME/my_master.cnf
SLAVE_CONFIG=$HOME/my_slave.cnf
MYSQL_PERF_DEFAULT_TABLE_COUNT=250
MYSQL_PERF_DEFAULT_TABLE_SIZE=25000
MYSQL_PERF_DEFAULT_PASSWORD=TAKE0one

function mysqlstart()
{
  MYSQL_DATADIR=$(cat $CMDDIR/mysql.cfg | awk '{print $1}')
  if [ ! -d $MYSQL_DATADIR/mysql ]; then
    echo "Data directory $MYSQL_DATADIR is not initialized yet"
    return
  fi

  if [ ! -f $MYSQL_CONFIG ]; then
    echo "Unable to find configuration file $MYSQL_CONFIG"
    return
  fi

  TYPE=$1
  if [ -z $TYPE ]; then
    echo "Start MySQL server in normal mode"
    mysqld --defaults-file=$MYSQL_CONFIG --datadir=$MYSQL_DATADIR --gdb > $MYSQL_DATADIR/error.log 2>&1 &
  elif [ $TYPE = "trace" ]; then
    echo "Start MySQL server in tracing mode"
    mysqld --defaults-file=$MYSQL_CONFIG --datadir=$MYSQL_DATADIR --gdb --debug=d:t:i:o,$PWD/mysqld.trace > $MYSQL_DATADIR/error.log 2>&1 &
  elif [ $TYPE = "querylog" ]; then
    echo "Start MySQL server with slow query log"
    mysqld --defaults-file=$MYSQL_CONFIG --datadir=$MYSQL_DATADIR --gdb --slow_query_log=1 --slow_query_log_file=$MYSQL_DATADIR/slowquery.log --long_query_time=0 --min_examined_row_limit=0 > $MYSQL_DATADIR/error.log 2>&1 &
  elif [ $TYPE = "gdb" ]; then
    echo "Debugging MySQL server with gdb"
    CMDFILE=$CMDDIR/loadmysql2.cmd
    cat $CMDDIR/loadmysql.cmd > $CMDFILE
    echo >> $CMDFILE
    echo "set pagination off" >> $CMDFILE
    echo "set non-stop on" >> $CMDFILE
    echo "set target-async on" >> $CMDFILE
    MYSQLDVER=$(mysqld --version)
    if [ ! -z "$(echo $MYSQLDVER | grep 8.0)" ]; then
      # MySQL 8.0
      echo "b srv_start" >> $CMDFILE
    else
      # MySQL 5.6 or 5.7
      echo "b innobase_start_or_create_for_mysql" >> $CMDFILE
    fi
    echo "b recv_recovery_from_checkpoint_start" >> $CMDFILE
    echo "r --defaults-file=$MYSQL_CONFIG --datadir=$MYSQL_DATADIR --gdb" >> $CMDFILE
    if [ `which cgdb` ]; then
      cgdb -x $CMDFILE $MYSQL_BASEDIR/bin/mysqld
    else
      gdb -x $CMDFILE $MYSQL_BASEDIR/bin/mysqld
    fi
  else
    echo "Unknown starting mode"
  fi
}

function mysqlstartmasterslave()
{
  MASTER_DATADIR=$(cat $CMDDIR/master.cfg | awk '{print $1}')
  if [ ! -d $MASTER_DATADIR/mysql ]; then
    echo "Master data directory $MASTER_DATADIR is not initialized yet"
    return
  fi
  SLAVE_DATADIR=$(cat $CMDDIR/slave.cfg | awk '{print $1}')
  if [ ! -d $SLAVE_DATADIR/mysql ]; then
    echo "Slave data directory $SLAVE_DATADIR is not initialized yet"
    return
  fi

  if [ ! -f $MASTER_CONFIG ]; then
    echo "Unable to find configuration file $MASTER_CONFIG"
    return
  fi
  if [ ! -f $SLAVE_CONFIG ]; then
    echo "Unable to find configuration file $SLAVE_CONFIG"
    return
  fi

  echo "Start MySQL master server in normal mode"
  mysqld --defaults-file=$MASTER_CONFIG --datadir=$MASTER_DATADIR --gdb > $MASTER_DATADIR/error.log 2>&1 &
  echo "Start MySQL slave server in normal mode"
  mysqld --defaults-file=$SLAVE_CONFIG --datadir=$SLAVE_DATADIR --gdb > $SLAVE_DATADIR/error.log 2>&1 &
}

function mysqlstop()
{
  if [ ! -f $MYSQL_CONFIG ]; then
    echo "Unable to find configuration file $MYSQL_CONFIG"
    return
  fi

  mysqladmin --defaults-file=$MYSQL_CONFIG --user=root --password=$MYSQL_PERF_DEFAULT_PASSWORD shutdown
}

function mysqlstopmasterslave()
{
  if [ ! -f $MASTER_CONFIG ]; then
    echo "Unable to find configuration file $MASTER_CONFIG"
    return
  fi
  if [ ! -f $SLAVE_CONFIG ]; then
    echo "Unable to find configuration file $SLAVE_CONFIG"
    return
  fi

  mysqladmin --defaults-file=$MASTER_CONFIG --user=root --password=$MYSQL_PERF_DEFAULT_PASSWORD shutdown
  mysqladmin --defaults-file=$SLAVE_CONFIG --user=root --password=$MYSQL_PERF_DEFAULT_PASSWORD shutdown
}

function mysqlconnect()
{
  DBNAME=$1
  if [ -z $DBNAME ]; then
    DBNAME=test
  fi

  if [ ! -f $MYSQL_CONFIG ]; then
    echo "Unable to find configuration file $MYSQL_CONFIG"
    return
  fi

  mysql --defaults-file=$MYSQL_CONFIG --user=root --password=$MYSQL_PERF_DEFAULT_PASSWORD $DBNAME
}

function mysqlconnectmaster()
{
  DBNAME=$1
  if [ -z $DBNAME ]; then
    DBNAME=test
  fi

  if [ ! -f $MASTER_CONFIG ]; then
    echo "Unable to find configuration file $MASTER_CONFIG"
    return
  fi

  mysql --defaults-file=$MASTER_CONFIG --user=root --password=$MYSQL_PERF_DEFAULT_PASSWORD $DBNAME
}

function mysqlconnectslave()
{
  DBNAME=$1
  if [ -z $DBNAME ]; then
    DBNAME=test
  fi

  if [ ! -f $SLAVE_CONFIG ]; then
    echo "Unable to find configuration file $SLAVE_CONFIG"
    return
  fi

  mysql --defaults-file=$SLAVE_CONFIG --user=root --password=$MYSQL_PERF_DEFAULT_PASSWORD $DBNAME
}

function mysqlreset()
{
  if [ ! -f $MYSQL_CONFIG ]; then
    echo "Unable to find configuration file $MYSQL_CONFIG"
    return
  fi

  MYSQLDVER=$(mysqld --version)
  if [ -z "$(echo $MYSQLDVER | grep 5.6)" ]; then
    if [ -z "$(echo $MYSQLDVER | grep 5.7)" ]; then
      # MySQL 8.0
      echo "Password already reset during initialization with MySQL 8.0"
    else
      # MySQL 5.7
      mysql --defaults-file=$MYSQL_CONFIG --user=root --password=$MYSQL_PERF_DEFAULT_PASSWORD -e "ALTER USER root@localhost IDENTIFIED BY '$MYSQL_PERF_DEFAULT_PASSWORD';"
    fi
  else
    # MySQL 5.6
    mysqladmin --defaults-file=$MYSQL_CONFIG --user=root --password=$MYSQL_PERF_DEFAULT_PASSWORD password "$MYSQL_PERF_DEFAULT_PASSWORD"
    if [ ! $? = 0 ]; then
      mysqladmin --defaults-file=$MYSQL_CONFIG --user=root password "$MYSQL_PERF_DEFAULT_PASSWORD"
    fi
    MYSQL_HOST=$(hostname)
    mysql --defaults-file=$MYSQL_CONFIG --user=root --password=$MYSQL_PERF_DEFAULT_PASSWORD -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'$MYSQL_HOST' IDENTIFIED BY '$MYSQL_PERF_DEFAULT_PASSWORD' WITH GRANT OPTION;"
  fi
}

function mysqlresetmasterslave()
{
  if [ ! -f $MASTER_CONFIG ]; then
    echo "Unable to find configuration file $MASTER_CONFIG"
    return
  fi
  if [ ! -f $SLAVE_CONFIG ]; then
    echo "Unable to find configuration file $SLAVE_CONFIG"
    return
  fi

  if [ -z "$(cat /etc/issue | grep SUSE)" ]; then
    LOCALIP=$(hostname -I | awk '{print $1}')
  else
    LOCALIP=$(hostname -i | awk '{print $1}')
  fi

  MYSQLDVER=$(mysqld --version)
  if [ -z "$(echo $MYSQLDVER | grep 5.6)" ]; then
    # MySQL 5.7 or 8.0
    if [ -z "$(echo $MYSQLDVER | grep 5.7)" ]; then
      echo "Password already reset during initialization with MySQL 8.0"
    else
      mysql --defaults-file=$MASTER_CONFIG --user=root --password=$MYSQL_PERF_DEFAULT_PASSWORD -e "ALTER USER root@localhost IDENTIFIED BY '$MYSQL_PERF_DEFAULT_PASSWORD';"
    fi
    mysql --defaults-file=$MASTER_CONFIG --user=root --password=$MYSQL_PERF_DEFAULT_PASSWORD -e "DROP USER IF EXISTS 'rpl'@'%';"
    mysql --defaults-file=$MASTER_CONFIG --user=root --password=$MYSQL_PERF_DEFAULT_PASSWORD -e "CREATE USER 'rpl'@'%' IDENTIFIED BY '$MYSQL_PERF_DEFAULT_PASSWORD';"
    mysql --defaults-file=$MASTER_CONFIG --user=root --password=$MYSQL_PERF_DEFAULT_PASSWORD -e "GRANT REPLICATION SLAVE ON *.* TO 'rpl'@'%';"
    mysql --defaults-file=$MASTER_CONFIG --user=root --password=$MYSQL_PERF_DEFAULT_PASSWORD -e "FLUSH PRIVILEGES;"

    mysql --defaults-file=$SLAVE_CONFIG --user=root --password=$MYSQL_PERF_DEFAULT_PASSWORD -e "SET GLOBAL super_read_only=0;"
    if [ -z "$(echo $MYSQLDVER | grep 5.7)" ]; then
      echo "Password already reset during initialization with MySQL 8.0"
    else
      mysql --defaults-file=$SLAVE_CONFIG --user=root --password=$MYSQL_PERF_DEFAULT_PASSWORD -e "ALTER USER root@localhost IDENTIFIED BY '$MYSQL_PERF_DEFAULT_PASSWORD';"
    fi
    mysql --defaults-file=$SLAVE_CONFIG --user=root --password=$MYSQL_PERF_DEFAULT_PASSWORD -e "STOP SLAVE;"
    mysql --defaults-file=$SLAVE_CONFIG --user=root --password=$MYSQL_PERF_DEFAULT_PASSWORD -e "CHANGE master to master_host='$LOCALIP', master_port=3600, master_user='rpl', master_password='$MYSQL_PERF_DEFAULT_PASSWORD', master_auto_position=1;"
    mysql --defaults-file=$SLAVE_CONFIG --user=root --password=$MYSQL_PERF_DEFAULT_PASSWORD -e "START SLAVE;"
    mysql --defaults-file=$SLAVE_CONFIG --user=root --password=$MYSQL_PERF_DEFAULT_PASSWORD -e "SET GLOBAL super_read_only=1;"
  else
    # MySQL 5.6
    mysqladmin --defaults-file=$MASTER_CONFIG --user=root --password=$MYSQL_PERF_DEFAULT_PASSWORD password "$MYSQL_PERF_DEFAULT_PASSWORD"
    if [ ! $? = 0 ]; then
      mysqladmin --defaults-file=$MASTER_CONFIG --user=root password "$MYSQL_PERF_DEFAULT_PASSWORD"
    fi
    MASTER_HOST=$(hostname)
    mysql --defaults-file=$MASTER_CONFIG --user=root --password=$MYSQL_PERF_DEFAULT_PASSWORD -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'$MASTER_HOST' IDENTIFIED BY '$MYSQL_PERF_DEFAULT_PASSWORD' WITH GRANT OPTION;"
    mysql --defaults-file=$MASTER_CONFIG --user=root --password=$MYSQL_PERF_DEFAULT_PASSWORD -e "DROP USER 'rpl'@'$MASTER_HOST';"
    mysql --defaults-file=$MASTER_CONFIG --user=root --password=$MYSQL_PERF_DEFAULT_PASSWORD -e "CREATE USER 'rpl'@'$MASTER_HOST' IDENTIFIED BY '$MYSQL_PERF_DEFAULT_PASSWORD';"
    mysql --defaults-file=$MASTER_CONFIG --user=root --password=$MYSQL_PERF_DEFAULT_PASSWORD -e "GRANT REPLICATION SLAVE ON *.* TO 'rpl'@'$MASTER_HOST';"
    mysql --defaults-file=$MASTER_CONFIG --user=root --password=$MYSQL_PERF_DEFAULT_PASSWORD -e "FLUSH PRIVILEGES;"
    mysql --defaults-file=$MASTER_CONFIG --user=root --password=$MYSQL_PERF_DEFAULT_PASSWORD -e "SHOW MASTER STATUS\G" > $HOME/master.status
    MASTER_BINLOG_FILE=$(cat $HOME/master.status | grep File | awk '{print $2}')
    MASTER_BINLOG_POS=$(cat $HOME/master.status | grep Position | awk '{print $2}')
    rm $HOME/master.status

    mysqladmin --defaults-file=$SLAVE_CONFIG --user=root --password=$MYSQL_PERF_DEFAULT_PASSWORD password "$MYSQL_PERF_DEFAULT_PASSWORD"
    if [ ! $? = 0 ]; then
      mysqladmin --defaults-file=$SLAVE_CONFIG --user=root password "$MYSQL_PERF_DEFAULT_PASSWORD"
    fi
    SLAVE_HOST=$(hostname)
    mysql --defaults-file=$SLAVE_CONFIG --user=root --password=$MYSQL_PERF_DEFAULT_PASSWORD -e "SET GLOBAL read_only=0;"
    mysql --defaults-file=$SLAVE_CONFIG --user=root --password=$MYSQL_PERF_DEFAULT_PASSWORD -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'$SLAVE_HOST' IDENTIFIED BY '$MYSQL_PERF_DEFAULT_PASSWORD' WITH GRANT OPTION;"
    mysql --defaults-file=$SLAVE_CONFIG --user=root --password=$MYSQL_PERF_DEFAULT_PASSWORD -e "STOP SLAVE;"
    mysql --defaults-file=$SLAVE_CONFIG --user=root --password=$MYSQL_PERF_DEFAULT_PASSWORD -e "CHANGE master to master_host='$LOCALIP', master_port=3600, master_user='rpl', master_password='$MYSQL_PERF_DEFAULT_PASSWORD', master_log_file='$MASTER_BINLOG_FILE', master_log_pos=$MASTER_BINLOG_POS;"
    mysql --defaults-file=$SLAVE_CONFIG --user=root --password=$MYSQL_PERF_DEFAULT_PASSWORD -e "START SLAVE;"
    mysql --defaults-file=$SLAVE_CONFIG --user=root --password=$MYSQL_PERF_DEFAULT_PASSWORD -e "SET GLOBAL read_only=1;"
  fi
}

function mysqlshowstatus()
{
  if [ ! -f $MASTER_CONFIG ]; then
    echo "Unable to find configuration file $MASTER_CONFIG"
    return
  fi
  if [ ! -f $SLAVE_CONFIG ]; then
    echo "Unable to find configuration file $SLAVE_CONFIG"
    return
  fi

  mysql --defaults-file=$MASTER_CONFIG --user=root --password=$MYSQL_PERF_DEFAULT_PASSWORD -e "SHOW MASTER STATUS\G"
  mysql --defaults-file=$SLAVE_CONFIG --user=root --password=$MYSQL_PERF_DEFAULT_PASSWORD -e "SHOW SLAVE STATUS\G"
}

function mysqlinit()
{
  MYSQLPROC=`ps -ef | grep $USER | grep mysqld | grep -v safe | grep -v grep | awk '{print $2}'`
  if [ -z "$MYSQLPROC" ]; then
    echo "MySQL server is not active"
  else
    mysqlstop
  fi

  MYSQLDVER=$(mysqld --version)
  if [ -z "$(cat /etc/issue | grep SUSE)" ]; then
    LOCALIP=$(hostname -I | awk '{print $1}')
  else
    LOCALIP=$(hostname -i | awk '{print $1}')
  fi
  SERVER_ID=$(echo $LOCALIP | awk -F'.' '{print $4}')

  BASE_DATADIR=$1
  if [ -z $1 ]; then
    BASE_DATADIR=$HOME
  fi

  BASE_LOGDIR=$2
  if [ -z $2 ]; then
    BASE_LOGDIR=$BASE_DATADIR
  fi

  if [ ! -d $BASE_DATADIR ]; then
    echo "Unable to find base data directory $BASE_DATADIR"
    return
  fi

  if [ ! -d $BASE_LOGDIR ]; then
    echo "Unable to find base log directory $BASE_LOGDIR"
    return
  fi

  MYSQL_DATADIR=$BASE_DATADIR/mysql_data
  rm -rf $MYSQL_DATADIR

  MYSQL_LOGDIR=$BASE_LOGDIR/mysql_log
  rm -rf $MYSQL_LOGDIR
  mkdir $MYSQL_LOGDIR

  rm -f $MYSQL_CONFIG
  cp $CMDDIR/mysql_perf.cnf $MYSQL_CONFIG

  PORT=3600
  if [ ! -z "$(echo $MYSQLDVER | grep 5.6)" ]; then
    sed -i '/secure-file-priv/d' $MYSQL_CONFIG
  fi
  sed -i '/innodb_file_per_table/d' $MYSQL_CONFIG
  sed -i '/innodb_buffer_pool_size/d' $MYSQL_CONFIG
  sed -i '/port/d' $MYSQL_CONFIG
  sed -i '/socket/d' $MYSQL_CONFIG
  sed -i '/skip-networking/d' $MYSQL_CONFIG
  sed -i '/performance_schema/d' $MYSQL_CONFIG
  sed -i '/thread_handling/d' $MYSQL_CONFIG
  sed -i '/innodb_log_file_size/d' $MYSQL_CONFIG
  sed -i '/innodb_io_capacity_max/d' $MYSQL_CONFIG
  sed -i '/innodb_io_capacity/d' $MYSQL_CONFIG
  echo "default-time-zone='+8:00'" >> $MYSQL_CONFIG
  echo "log-bin=mysql-bin" >> $MYSQL_CONFIG
  echo "sync_binlog=1" >> $MYSQL_CONFIG
  echo "server-id=$SERVER_ID" >> $MYSQL_CONFIG
  echo "binlog-format=row" >> $MYSQL_CONFIG
  if [ -z "$(echo $MYSQLDVER | grep 5.6)" ]; then
    # Turn on GTID for MySQL 5.7 or 8.0
    echo "gtid-mode=on" >> $MYSQL_CONFIG
    echo "enforce-gtid-consistency" >> $MYSQL_CONFIG
  fi
  echo "log-slave-updates" >> $MYSQL_CONFIG
  echo "master-info-repository=TABLE" >> $MYSQL_CONFIG
  echo "relay-log-info-repository=TABLE" >> $MYSQL_CONFIG
  echo "binlog-checksum=NONE" >> $MYSQL_CONFIG
  echo "innodb_log_group_home_dir=$MYSQL_LOGDIR" >> $MYSQL_CONFIG
  echo "innodb_log_file_size=512M" >> $MYSQL_CONFIG
  echo "innodb_data_file_path=idbdata1:512M:autoextend" >> $MYSQL_CONFIG
  echo "innodb_io_capacity=6000" >> $MYSQL_CONFIG
  echo "innodb_io_capacity_max=10000" >> $MYSQL_CONFIG
  echo "innodb_file_per_table=1" >> $MYSQL_CONFIG
  echo "innodb_buffer_pool_size=1G" >> $MYSQL_CONFIG
  echo "bind-address=0.0.0.0" >> $MYSQL_CONFIG
  #echo "skip-grant-tables" >> $MYSQL_CONFIG
  echo "port=$PORT" >> $MYSQL_CONFIG
  echo "socket=/tmp/mysql.socket.$USER" >> $MYSQL_CONFIG
  echo "[client]" >> $MYSQL_CONFIG
  echo "port=$PORT" >> $MYSQL_CONFIG
  echo "socket=/tmp/mysql.socket.$USER" >> $MYSQL_CONFIG

  echo $MYSQLDVER
  if [ -z "$(echo $MYSQLDVER | grep '5\.6')" ]; then
    echo "Initialize data directory with password $MYSQL_PERF_DEFAULT_PASSWORD"
    if [ -z "$(echo $MYSQLDVER | grep '5\.7')" ]; then
      # MySQL 8.0
      mysqld --defaults-file=$MYSQL_CONFIG --initialize --init-file=$CMDDIR/mysql8_init.sql --basedir=$MYSQL_BASEDIR --datadir=$MYSQL_DATADIR
    else
      # MySQL 5.7
      mysqld --defaults-file=$MYSQL_CONFIG --initialize --init-file=$CMDDIR/mysql_init.sql --basedir=$MYSQL_BASEDIR --datadir=$MYSQL_DATADIR
    fi
    cat $MYSQL_DATADIR/error.log
  else
    # MySQL 5.6
    echo "Install database with directory $MYSQL_DATADIR"
    mysql_install_db --defaults-file=$MYSQL_CONFIG --user=root --basedir=$MYSQL_BASEDIR --datadir=$MYSQL_DATADIR
  fi

  # Save configuration
  echo "$MYSQL_DATADIR $MYSQL_LOGDIR" > $CMDDIR/mysql.cfg
}

function mysqlinitmasterslave()
{
  MYSQLPROC=`ps -ef | grep $USER | grep mysqld | grep -v safe | grep -v grep | awk '{print $2}'`
  if [ -z "$MYSQLPROC" ]; then
    echo "MySQL server is not active"
  else
    mysqlstopmaster
    mysqlstopslave
  fi

  MYSQLDVER=$(mysqld --version)

  BASE_DATADIR=$1
  if [ -z $1 ]; then
    BASE_DATADIR=$HOME
  fi

  BASE_LOGDIR=$2
  if [ -z $2 ]; then
    BASE_LOGDIR=$BASE_DATADIR
  fi

  if [ ! -d $BASE_DATADIR ]; then
    echo "Unable to find base data directory $BASE_DATADIR"
    return
  fi

  if [ ! -d $BASE_LOGDIR ]; then
    echo "Unable to find base log directory $BASE_LOGDIR"
    return
  fi

  MASTER_DATADIR=$BASE_DATADIR/master_data
  rm -rf $MASTER_DATADIR
  SLAVE_DATADIR=$BASE_DATADIR/slave_data
  rm -rf $SLAVE_DATADIR

  MASTER_LOGDIR=$BASE_LOGDIR/master_log
  rm -rf $MASTER_LOGDIR
  mkdir $MASTER_LOGDIR
  SLAVE_LOGDIR=$BASE_LOGDIR/slave_log
  rm -rf $SLAVE_LOGDIR
  mkdir $SLAVE_LOGDIR

  rm -f $MASTER_CONFIG
  cp $CMDDIR/mysql_perf.cnf $MASTER_CONFIG
  rm -f $SLAVE_CONFIG
  cp $CMDDIR/mysql_perf.cnf $SLAVE_CONFIG

  PORT=3600
  if [ ! -z "$(echo $MYSQLDVER | grep 5.6)" ]; then
    sed -i '/secure-file-priv/d' $MASTER_CONFIG
  fi
  sed -i '/innodb_file_per_table/d' $MASTER_CONFIG
  sed -i '/innodb_buffer_pool_size/d' $MASTER_CONFIG
  sed -i '/port/d' $MASTER_CONFIG
  sed -i '/socket/d' $MASTER_CONFIG
  sed -i '/skip-networking/d' $MASTER_CONFIG
  sed -i '/performance_schema/d' $MASTER_CONFIG
  sed -i '/thread_handling/d' $MASTER_CONFIG
  sed -i '/innodb_log_file_size/d' $MASTER_CONFIG
  sed -i '/innodb_io_capacity_max/d' $MASTER_CONFIG
  sed -i '/innodb_io_capacity/d' $MASTER_CONFIG
  echo "default-time-zone='+8:00'" >> $MASTER_CONFIG
  echo "log-bin=mysql-bin" >> $MASTER_CONFIG
  echo "sync_binlog=1" >> $MASTER_CONFIG
  echo "server-id=1" >> $MASTER_CONFIG
  echo "binlog-format=row" >> $MASTER_CONFIG
  if [ -z "$(echo $MYSQLDVER | grep 5.6)" ]; then
    # Turn on GTID for MySQL 5.7 or 8.0
    echo "gtid-mode=on" >> $MASTER_CONFIG
    echo "enforce-gtid-consistency" >> $MASTER_CONFIG
  fi
  echo "log-slave-updates" >> $MASTER_CONFIG
  echo "master-info-repository=TABLE" >> $MASTER_CONFIG
  echo "relay-log-info-repository=TABLE" >> $MASTER_CONFIG
  echo "binlog-checksum=NONE" >> $MASTER_CONFIG
  echo "innodb_log_group_home_dir=$MASTER_LOGDIR" >> $MASTER_CONFIG
  echo "innodb_log_file_size=1G" >> $MASTER_CONFIG
  echo "innodb_data_file_path=idbdata1:2G:autoextend" >> $MASTER_CONFIG
  echo "innodb_io_capacity=6000" >> $MASTER_CONFIG
  echo "innodb_io_capacity_max=10000" >> $MASTER_CONFIG
  echo "innodb_file_per_table=1" >> $MASTER_CONFIG
  echo "innodb_buffer_pool_size=64G" >> $MASTER_CONFIG
  echo "bind-address=0.0.0.0" >> $MASTER_CONFIG
  echo "port=$PORT" >> $MASTER_CONFIG
  echo "socket=/tmp/mysql.socket.$USER.master" >> $MASTER_CONFIG
  echo "[client]" >> $MASTER_CONFIG
  echo "port=$PORT" >> $MASTER_CONFIG
  echo "socket=/tmp/mysql.socket.$USER.master" >> $MASTER_CONFIG

  PORT=$(( PORT+1 ))    # increments $PORT
  if [ ! -z "$(echo $MYSQLDVER | grep 5.6)" ]; then
    sed -i '/secure-file-priv/d' $SLAVE_CONFIG
  fi
  sed -i '/innodb_file_per_table/d' $SLAVE_CONFIG
  sed -i '/innodb_buffer_pool_size/d' $SLAVE_CONFIG
  sed -i '/port/d' $SLAVE_CONFIG
  sed -i '/socket/d' $SLAVE_CONFIG
  sed -i '/skip-networking/d' $SLAVE_CONFIG
  sed -i '/performance_schema/d' $SLAVE_CONFIG
  sed -i '/thread_handling/d' $SLAVE_CONFIG
  sed -i '/innodb_log_file_size/d' $SLAVE_CONFIG
  sed -i '/innodb_io_capacity_max/d' $SLAVE_CONFIG
  sed -i '/innodb_io_capacity/d' $SLAVE_CONFIG
  echo "default-time-zone='+8:00'" >> $SLAVE_CONFIG
  echo "log-bin=mysql-bin" >> $SLAVE_CONFIG
  echo "sync_binlog=1" >> $SLAVE_CONFIG
  echo "server-id=2" >> $SLAVE_CONFIG
  echo "binlog-format=row" >> $SLAVE_CONFIG
  if [ -z "$(echo $MYSQLDVER | grep 5.6)" ]; then
    # Turn on GTID for MySQL 5.7 or 8.0
    echo "gtid-mode=on" >> $SLAVE_CONFIG
    echo "enforce-gtid-consistency" >> $SLAVE_CONFIG
  fi
  echo "log-slave-updates" >> $SLAVE_CONFIG
  echo "master-info-repository=TABLE" >> $SLAVE_CONFIG
  echo "relay-log-info-repository=TABLE" >> $SLAVE_CONFIG
  echo "binlog-checksum=NONE" >> $SLAVE_CONFIG
  echo "innodb_log_group_home_dir=$SLAVE_LOGDIR" >> $SLAVE_CONFIG
  echo "innodb_log_file_size=1G" >> $SLAVE_CONFIG
  echo "innodb_data_file_path=idbdata1:2G:autoextend" >> $SLAVE_CONFIG
  echo "innodb_io_capacity=6000" >> $SLAVE_CONFIG
  echo "innodb_io_capacity_max=10000" >> $SLAVE_CONFIG
  echo "innodb_file_per_table=1" >> $SLAVE_CONFIG
  echo "innodb_buffer_pool_size=64G" >> $SLAVE_CONFIG
  echo "bind-address=0.0.0.0" >> $SLAVE_CONFIG
  echo "port=$PORT" >> $SLAVE_CONFIG
  echo "socket=/tmp/mysql.socket.$USER.slave" >> $SLAVE_CONFIG
  echo "[client]" >> $SLAVE_CONFIG
  echo "port=$PORT" >> $SLAVE_CONFIG
  echo "socket=/tmp/mysql.socket.$USER.slave" >> $SLAVE_CONFIG

  echo $MYSQLDVER
  if [ -z "$(echo $MYSQLDVER | grep '5\.6')" ]; then
    echo "Initialize master data directory with password $MYSQL_PERF_DEFAULT_PASSWORD"
    if [ -z "$(echo $MYSQLDVER | grep '5\.7')" ]; then
      # MySQL 8.0
      mysqld --defaults-file=$MASTER_CONFIG --initialize --init-file=$CMDDIR/mysql8_init.sql --basedir=$MYSQL_BASEDIR --datadir=$MASTER_DATADIR
        else
      # MySQL 5.7
      mysqld --defaults-file=$MASTER_CONFIG --initialize --init-file=$CMDDIR/mysql_init.sql --basedir=$MYSQL_BASEDIR --datadir=$MASTER_DATADIR
    fi
    cat $MASTER_DATADIR/error.log
    echo "Initialize slave data directory with password $MYSQL_PERF_DEFAULT_PASSWORD"
    if [ -z "$(echo $MYSQLDVER | grep '5\.7')" ]; then
      # MySQL 8.0
      mysqld --defaults-file=$SLAVE_CONFIG --initialize --init-file=$CMDDIR/mysql8_init.sql --basedir=$MYSQL_BASEDIR --datadir=$SLAVE_DATADIR
    else
      # MySQL 5.7
      mysqld --defaults-file=$SLAVE_CONFIG --initialize --init-file=$CMDDIR/mysql_init.sql --basedir=$MYSQL_BASEDIR --datadir=$SLAVE_DATADIR
    fi
    cat $SLAVE_DATADIR/error.log
  else
    # MySQL 5.6
    echo "Install master database with directory $MASTER_DATADIR"
    mysql_install_db --defaults-file=$MASTER_CONFIG --user=root --basedir=$MYSQL_BASEDIR --datadir=$MASTER_DATADIR
    echo "Install slave database with directory $SLAVE_DATADIR"
    mysql_install_db --defaults-file=$SLAVE_CONFIG --user=root --basedir=$MYSQL_BASEDIR --datadir=$SLAVE_DATADIR
  fi

  # Save configuration
  echo "$MASTER_DATADIR $MASTER_LOGDIR" > $CMDDIR/master.cfg
  echo "$SLAVE_DATADIR $SLAVE_LOGDIR" > $CMDDIR/slave.cfg
}

function mysqlattach()
{
  MYSQLD=$MYSQL_BASEDIR/bin/mysqld
  MYSQLPROC=$(ps -ef | grep $USER | grep mysqld | grep "$MYSQL_CONFIG" | grep -v safe | grep -v grep | awk '{print $2}')
  if [ -z "$MYSQLPROC" ]; then
    echo "Can't find the mysqld to be attached"
  else
    CMDFILE=$CMDDIR/loadmysql.cmd
    gdb -x $CMDFILE $MYSQLD $MYSQLPROC
  fi
}

function mysqlattachmaster()
{
  MYSQLD=$MYSQL_BASEDIR/bin/mysqld
  MYSQLPROC=$(ps -ef | grep $USER | grep mysqld | grep "$MASTER_CONFIG" | grep -v safe | grep -v grep | awk '{print $2}')
  if [ -z "$MYSQLPROC" ]; then
    echo "Can't find the master mysqld to be attached"
  else
    gdb -x $CMDDIR/loadmysql.cmd $MYSQLD $MYSQLPROC
  fi
}

function mysqlattachslave()
{
  MYSQLD=$MYSQL_BASEDIR/bin/mysqld
  MYSQLPROC=$(ps -ef | grep $USER | grep mysqld | grep "$SLAVE_CONFIG" | grep -v safe | grep -v grep | awk '{print $2}')
  if [ -z "$MYSQLPROC" ]; then
    echo "Can't find the slave mysqld to be attached"
  else
    gdb -x $CMDDIR/loadmysql.cmd $MYSQLD $MYSQLPROC
  fi
}

function mysqlprepare()
{
  if [ -z "$(cat /etc/issue | grep SUSE)" ]; then
    LOCALIP=$(hostname -I | awk '{print $1}')
  else
    LOCALIP=$(hostname -i | awk '{print $1}')
  fi

  DBNAME=test
  DBUSER=root
  DBPORT=3600
  DBHOST=$1
  if [ -z $DBHOST ]; then
    DBHOST=$LOCALIP
  fi

  sysbench --test=tests/db/parallel_prepare.lua --oltp_tables_count=$MYSQL_PERF_DEFAULT_TABLE_COUNT --mysql-db=$DBNAME --oltp-table-size=$MYSQL_PERF_DEFAULT_TABLE_SIZE --mysql-user=$DBUSER --mysql-password=$MYSQL_PERF_DEFAULT_PASSWORD --mysql-port=$DBPORT --mysql-host=$DBHOST --num-threads=$MYSQL_PERF_DEFAULT_TABLE_COUNT --report-interval=10 run
}

function mysqlrunwrite()
{
  if [ -z "$(cat /etc/issue | grep SUSE)" ]; then
    LOCALIP=$(hostname -I | awk '{print $1}')
  else
    LOCALIP=$(hostname -i | awk '{print $1}')
  fi

  DBNAME=test
  DBUSER=root
  DBPORT=3600
  DBHOST=$3
  if [ -z $DBHOST ]; then
    DBHOST=$LOCALIP
  fi

  DURATION=$1
  CONCURRENCY=$2
  if [ -z $DURATION ]; then
    DURATION=60
  fi
  if [ -z $CONCURRENCY ]; then
    CONCURRENCY=100
  fi

  sysbench --test=tests/db/oltp.lua --mysql-table-engine=innodb --oltp_tables_count=$MYSQL_PERF_DEFAULT_TABLE_COUNT --mysql-db=$DBNAME --oltp-table-size=$MYSQL_PERF_DEFAULT_TABLE_SIZE --mysql-user=$DBUSER --mysql-password=$MYSQL_PERF_DEFAULT_PASSWORD --mysql-port=$DBPORT --mysql-host=$DBHOST --rand-type=uniform --num-threads=$CONCURRENCY --max-requests=0 --rand-seed=42 --max-time=$DURATION --oltp-read-only=off --report-interval=10 run
}

function mysqlrunread()
{
  if [ -z "$(cat /etc/issue | grep SUSE)" ]; then
    LOCALIP=$(hostname -I | awk '{print $1}')
  else
    LOCALIP=$(hostname -i | awk '{print $1}')
  fi

  DBNAME=test
  DBUSER=root
  DBPORT=3600
  DBHOST=$3
  if [ -z $DBHOST ]; then
    DBHOST=$LOCALIP
  fi

  DURATION=$1
  CONCURRENCY=$2
  if [ -z $DURATION ]; then
    DURATION=60
  fi
  if [ -z $CONCURRENCY ]; then
    CONCURRENCY=100
  fi

  sysbench --test=tests/db/oltp.lua --oltp_tables_count=$MYSQL_PERF_DEFAULT_TABLE_COUNT --mysql-db=$DBNAME --oltp-table-size=$MYSQL_PERF_DEFAULT_TABLE_SIZE --mysql-user=$DBUSER --mysql-password=$MYSQL_PERF_DEFAULT_PASSWORD --mysql-port=$DBPORT --mysql-host=$DBHOST --db-dirver=mysql --num-threads=$CONCURRENCY --max-requests=0 --oltp_simple_ranges=0 --oltp-distinct-ranges=0 --oltp-sum-ranges=0 --oltp-order-ranges=0 --rand-seed=42 --max-time=$DURATION --oltp-read-only=on --report-interval=10 run
}

function mysqlrunpurewrite()
{
  if [ -z "$(cat /etc/issue | grep SUSE)" ]; then
    LOCALIP=$(hostname -I | awk '{print $1}')
  else
    LOCALIP=$(hostname -i | awk '{print $1}')
  fi

  DBNAME=test
  DBUSER=root
  DBPORT=3600
  DBHOST=$3
  if [ -z $DBHOST ]; then
    DBHOST=$LOCALIP
  fi

  DURATION=$1
  CONCURRENCY=$2
  if [ -z $DURATION ]; then
    DURATION=60
  fi
  if [ -z $CONCURRENCY ]; then
    CONCURRENCY=100
  fi

  sysbench --test=tests/db/oltp.lua --mysql-table-engine=innodb --oltp_tables_count=$MYSQL_PERF_DEFAULT_TABLE_COUNT --mysql-db=$DBNAME --oltp-table-size=$MYSQL_PERF_DEFAULT_TABLE_SIZE --mysql-user=$DBUSER --mysql-password=$MYSQL_PERF_DEFAULT_PASSWORD --mysql-port=$DBPORT --mysql-host=$DBHOST --rand-type=uniform --num-threads=$CONCURRENCY --max-requests=0 --max-requests=0 --oltp_simple_ranges=0 --oltp-distinct-ranges=0 --oltp-sum-ranges=0 --oltp-order-ranges=0 --oltp-point-selects=0 --rand-seed=42 --max-time=$DURATION --oltp-read-only=off --report-interval=10 run
}
