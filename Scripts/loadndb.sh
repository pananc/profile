NDB_BASEDIR=$HOME/mysql
NDB_CONFIG=$HOME/ndb.cnf
NDB_PRIMARY_CONFIG=$HOME/ndb_primary.cnf
NDB_REPLICA_CONFIG=$HOME/ndb_replica.cnf
NDB_DEFAULT_TABLE_COUNT=250
NDB_DEFAULT_TABLE_SIZE=25000
NDB_DEFAULT_PASSWORD=TAKE0one

function ndbstart()
{
  NDB_DATADIR=$(cat $CMDDIR/ndb.cfg | awk '{print $1}')
  if [ ! -d $NDB_DATADIR/mysql ]; then
    echo "Data directory $NDB_DATADIR is not initialized yet"
    return
  fi

  if [ ! -f $NDB_CONFIG ]; then
    echo "Unable to find configuration file $NDB_CONFIG"
    return
  fi

  TYPE=$1
  if [ -z $TYPE ]; then
    echo "Start ByteNDB server in normal mode"
    mysqld --defaults-file=$NDB_CONFIG --datadir=$NDB_DATADIR --gdb > $NDB_DATADIR/error.log 2>&1 &
  elif [ $TYPE = "trace" ]; then
    echo "Start ByteNDB server in tracing mode"
    mysqld --defaults-file=$NDB_CONFIG --datadir=$NDB_DATADIR --gdb --debug=d:t:i:o,$PWD/mysqld.trace > $NDB_DATADIR/error.log 2>&1 &
  elif [ $TYPE = "querylog" ]; then
    echo "Start ByteNDB server with slow query log"
    mysqld --defaults-file=$NDB_CONFIG --datadir=$NDB_DATADIR --gdb --slow_query_log=1 --slow_query_log_file=$NDB_DATADIR/slowquery.log --long_query_time=0 --min_examined_row_limit=0 > $NDB_DATADIR/error.log 2>&1 &
  elif [ $TYPE = "gdb" ]; then
    echo "Debugging ByteNDB server with gdb"
    CMDFILE=$CMDDIR/loadmysql2.cmd
    cat $CMDDIR/loadmysql.cmd > $CMDFILE
    echo >> $CMDFILE
    echo "set pagination off" >> $CMDFILE
    echo "set non-stop on" >> $CMDFILE
    echo "set target-async on" >> $CMDFILE
    echo "b srv_start" >> $CMDFILE
    echo "b recv_recovery_from_checkpoint_start" >> $CMDFILE
    echo "r --defaults-file=$NDB_CONFIG --datadir=$NDB_DATADIR --gdb" >> $CMDFILE
    if [ `which cgdb` ]; then
      cgdb -x $CMDFILE $NDB_BASEDIR/bin/mysqld
    else
      gdb -x $CMDFILE $NDB_BASEDIR/bin/mysqld
    fi
  else
    echo "Unknown starting mode"
  fi
}

function ndbstartprimaryreplica()
{
  PRIMARY_DATADIR=$(cat $CMDDIR/primary.cfg | awk '{print $1}')
  if [ ! -d $PRIMARY_DATADIR/mysql ]; then
    echo "Master data directory $PRIMARY_DATADIR is not initialized yet"
    return
  fi
  REPLICA_DATADIR=$(cat $CMDDIR/replica.cfg | awk '{print $1}')
  if [ ! -d $REPLICA_DATADIR/mysql ]; then
    echo "Slave data directory $REPLICA_DATADIR is not initialized yet"
    return
  fi

  if [ ! -f $NDB_PRIMARY_CONFIG ]; then
    echo "Unable to find configuration file $NDB_PRIMARY_CONFIG"
    return
  fi
  if [ ! -f $NDB_REPLICA_CONFIG ]; then
    echo "Unable to find configuration file $NDB_REPLICA_CONFIG"
    return
  fi

  echo "Start ByteNDB primary server in normal mode"
  mysqld --defaults-file=$NDB_PRIMARY_CONFIG --datadir=$PRIMARY_DATADIR --gdb > $PRIMARY_DATADIR/error.log 2>&1 &
  echo "Start ByteNDB replica server in normal mode"
  mysqld --defaults-file=$NDB_REPLICA_CONFIG --datadir=$REPLICA_DATADIR --gdb > $REPLICA_DATADIR/error.log 2>&1 &
}

function ndbstop()
{
  if [ ! -f $NDB_CONFIG ]; then
    echo "Unable to find configuration file $NDB_CONFIG"
    return
  fi

  mysqladmin --defaults-file=$NDB_CONFIG --user=root --password=$NDB_DEFAULT_PASSWORD shutdown
}

function ndbstopprimaryreplica()
{
  if [ ! -f $NDB_PRIMARY_CONFIG ]; then
    echo "Unable to find configuration file $NDB_PRIMARY_CONFIG"
    return
  fi
  if [ ! -f $NDB_REPLICA_CONFIG ]; then
    echo "Unable to find configuration file $NDB_REPLICA_CONFIG"
    return
  fi

  mysqladmin --defaults-file=$NDB_PRIMARY_CONFIG --user=root --password=$NDB_DEFAULT_PASSWORD shutdown
  mysqladmin --defaults-file=$NDB_REPLICA_CONFIG --user=root --password=$NDB_DEFAULT_PASSWORD shutdown
}

function ndbconnect()
{
  DBNAME=$1
  if [ -z $DBNAME ]; then
    DBNAME=test
  fi

  if [ ! -f $NDB_CONFIG ]; then
    echo "Unable to find configuration file $NDB_CONFIG"
    return
  fi

  mysql --defaults-file=$NDB_CONFIG --user=root --password=$NDB_DEFAULT_PASSWORD $DBNAME
}

function ndbconnectprimary()
{
  DBNAME=$1
  if [ -z $DBNAME ]; then
    DBNAME=test
  fi

  if [ ! -f $NDB_PRIMARY_CONFIG ]; then
    echo "Unable to find configuration file $NDB_PRIMARY_CONFIG"
    return
  fi

  mysql --defaults-file=$NDB_PRIMARY_CONFIG --user=root --password=$NDB_DEFAULT_PASSWORD $DBNAME
}

function ndbconnectreplica()
{
  DBNAME=$1
  if [ -z $DBNAME ]; then
    DBNAME=test
  fi

  if [ ! -f $NDB_REPLICA_CONFIG ]; then
    echo "Unable to find configuration file $NDB_REPLICA_CONFIG"
    return
  fi

  mysql --defaults-file=$NDB_REPLICA_CONFIG --user=root --password=$NDB_DEFAULT_PASSWORD $DBNAME
}

function ndbinit()
{
  NDBPROC=`ps -ef | grep $USER | grep mysqld | grep -v safe | grep -v grep | awk '{print $2}'`
  if [ -z "$NDBPROC" ]; then
    echo "ByteNDB server is not active"
  else
    ndbstop
  fi

  MYSQLDVER=$(mysqld --version)
  if [ -z "$(cat /etc/issue | grep SUSE)" ]; then
    LOCALIP=$(hostname -I | awk '{print $1}')
  else
    LOCALIP=$(hostname -i | awk '{print $1}')
  fi

  BASE_DATADIR=$1
  if [ -z $1 ]; then
    BASE_DATADIR=$HOME
  fi

  if [ ! -d $BASE_DATADIR ]; then
    echo "Unable to find base data directory $BASE_DATADIR"
    return
  fi

  NDB_DATADIR=$BASE_DATADIR/ndb_data
  rm -rf $NDB_DATADIR

  rm -f $NDB_CONFIG
  cp $CMDDIR/mysql_perf.cnf $NDB_CONFIG

  PORT=3600
  if [ ! -z "$(echo $MYSQLDVER | grep 5.6)" ]; then
    sed -i '/secure-file-priv/d' $NDB_CONFIG
  fi
  sed -i '/innodb_file_per_table/d' $NDB_CONFIG
  sed -i '/innodb_buffer_pool_size/d' $NDB_CONFIG
  sed -i '/port/d' $NDB_CONFIG
  sed -i '/socket/d' $NDB_CONFIG
  sed -i '/skip-networking/d' $NDB_CONFIG
  sed -i '/performance_schema/d' $NDB_CONFIG
  sed -i '/thread_handling/d' $NDB_CONFIG
  sed -i '/innodb_log_file_size/d' $NDB_CONFIG
  sed -i '/innodb_io_capacity_max/d' $NDB_CONFIG
  sed -i '/innodb_io_capacity/d' $NDB_CONFIG
  echo "default-time-zone='+8:00'" >> $NDB_CONFIG
  echo "log-bin=mysql-bin" >> $NDB_CONFIG
  echo "sync_binlog=1" >> $NDB_CONFIG
  echo "server-id=1" >> $NDB_CONFIG
  echo "binlog-format=row" >> $NDB_CONFIG
  # Turn on GTID for ByteNDB
  echo "gtid-mode=on" >> $NDB_CONFIG
  echo "enforce-gtid-consistency" >> $NDB_CONFIG
  echo "log-slave-updates" >> $NDB_CONFIG
  echo "master-info-repository=TABLE" >> $NDB_CONFIG
  echo "relay-log-info-repository=TABLE" >> $NDB_CONFIG
  echo "binlog-checksum=NONE" >> $NDB_CONFIG
  # Disable binlog for ByteNDB
  echo "disable_log_bin" >> $NDB_CONFIG
  echo "innodb_data_file_path=ibdata1:512M:autoextend" >> $NDB_CONFIG
  echo "innodb_io_capacity=6000" >> $NDB_CONFIG
  echo "innodb_io_capacity_max=10000" >> $NDB_CONFIG
  echo "innodb_file_per_table=1" >> $NDB_CONFIG
  echo "innodb_buffer_pool_size=1G" >> $NDB_CONFIG
  echo "innodb_mock_server_host=localhost:8080" >> $NDB_CONFIG
  echo "bind-address=0.0.0.0" >> $NDB_CONFIG
  #echo "skip-grant-tables" >> $NDB_CONFIG
  echo "port=$PORT" >> $NDB_CONFIG
  echo "socket=/tmp/ndb.socket.$USER" >> $NDB_CONFIG
  echo "[client]" >> $NDB_CONFIG
  echo "port=$PORT" >> $NDB_CONFIG
  echo "socket=/tmp/ndb.socket.$USER" >> $NDB_CONFIG

  echo $MYSQLDVER
  echo "Initialize data directory with password $NDB_DEFAULT_PASSWORD"
  mysqld --defaults-file=$NDB_CONFIG --initialize --init-file=$CMDDIR/mysql8_init.sql --basedir=$NDB_BASEDIR --datadir=$NDB_DATADIR
  cat $NDB_DATADIR/error.log

  # Save configuration
  echo "$NDB_DATADIR" > $CMDDIR/ndb.cfg
}

function ndbinitprimaryreplica()
{
  NDBPROC=`ps -ef | grep $USER | grep mysqld | grep -v safe | grep -v grep | awk '{print $2}'`
  if [ -z "$NDBPROC" ]; then
    echo "ByteNDB server is not active"
  else
    ndbstopprimary
    ndbstopreplica
  fi

  MYSQLDVER=$(mysqld --version)

  BASE_DATADIR=$1
  if [ -z $1 ]; then
    BASE_DATADIR=$HOME
  fi

  if [ ! -d $BASE_DATADIR ]; then
    echo "Unable to find base data directory $BASE_DATADIR"
    return
  fi

  PRIMARY_DATADIR=$BASE_DATADIR/primary_data
  rm -rf $PRIMARY_DATADIR
  REPLICA_DATADIR=$BASE_DATADIR/replica_data
  rm -rf $REPLICA_DATADIR

  rm -f $NDB_PRIMARY_CONFIG
  cp $CMDDIR/mysql_perf.cnf $NDB_PRIMARY_CONFIG
  rm -f $NDB_REPLICA_CONFIG
  cp $CMDDIR/mysql_perf.cnf $NDB_REPLICA_CONFIG

  PORT=3600
  if [ ! -z "$(echo $MYSQLDVER | grep 5.6)" ]; then
    sed -i '/secure-file-priv/d' $NDB_PRIMARY_CONFIG
  fi
  sed -i '/innodb_file_per_table/d' $NDB_PRIMARY_CONFIG
  sed -i '/innodb_buffer_pool_size/d' $NDB_PRIMARY_CONFIG
  sed -i '/port/d' $NDB_PRIMARY_CONFIG
  sed -i '/socket/d' $NDB_PRIMARY_CONFIG
  sed -i '/skip-networking/d' $NDB_PRIMARY_CONFIG
  sed -i '/performance_schema/d' $NDB_PRIMARY_CONFIG
  sed -i '/thread_handling/d' $NDB_PRIMARY_CONFIG
  sed -i '/innodb_log_file_size/d' $NDB_PRIMARY_CONFIG
  sed -i '/innodb_io_capacity_max/d' $NDB_PRIMARY_CONFIG
  sed -i '/innodb_io_capacity/d' $NDB_PRIMARY_CONFIG
  echo "default-time-zone='+8:00'" >> $NDB_PRIMARY_CONFIG
  echo "log-bin=mysql-bin" >> $NDB_PRIMARY_CONFIG
  echo "sync_binlog=1" >> $NDB_PRIMARY_CONFIG
  echo "server-id=1" >> $NDB_PRIMARY_CONFIG
  echo "binlog-format=row" >> $NDB_PRIMARY_CONFIG
  # Turn on GTID for ByteNDB
  echo "gtid-mode=on" >> $NDB_PRIMARY_CONFIG
  echo "enforce-gtid-consistency" >> $NDB_PRIMARY_CONFIG
  echo "log-slave-updates" >> $NDB_PRIMARY_CONFIG
  echo "master-info-repository=TABLE" >> $NDB_PRIMARY_CONFIG
  echo "relay-log-info-repository=TABLE" >> $NDB_PRIMARY_CONFIG
  echo "binlog-checksum=NONE" >> $NDB_PRIMARY_CONFIG
  # Disable binlog for ByteNDB
  echo "disable_log_bin" >> $NDB_PRIMARY_CONFIG
  echo "innodb_data_file_path=ibdata1:512M:autoextend" >> $NDB_PRIMARY_CONFIG
  echo "innodb_io_capacity=6000" >> $NDB_PRIMARY_CONFIG
  echo "innodb_io_capacity_max=10000" >> $NDB_PRIMARY_CONFIG
  echo "innodb_file_per_table=1" >> $NDB_PRIMARY_CONFIG
  echo "innodb_buffer_pool_size=1G" >> $NDB_PRIMARY_CONFIG
  echo "innodb_mock_server_host=localhost:8080" >> $NDB_PRIMARY_CONFIG
  echo "bind-address=0.0.0.0" >> $NDB_PRIMARY_CONFIG
  echo "port=$PORT" >> $NDB_PRIMARY_CONFIG
  echo "socket=/tmp/ndb.socket.$USER.primary" >> $NDB_PRIMARY_CONFIG
  echo "[client]" >> $NDB_PRIMARY_CONFIG
  echo "port=$PORT" >> $NDB_PRIMARY_CONFIG
  echo "socket=/tmp/ndb.socket.$USER.primary" >> $NDB_PRIMARY_CONFIG

  PORT=$(( PORT+1 ))    # increments $PORT
  if [ ! -z "$(echo $MYSQLDVER | grep 5.6)" ]; then
    sed -i '/secure-file-priv/d' $NDB_REPLICA_CONFIG
  fi
  sed -i '/innodb_file_per_table/d' $NDB_REPLICA_CONFIG
  sed -i '/innodb_buffer_pool_size/d' $NDB_REPLICA_CONFIG
  sed -i '/port/d' $NDB_REPLICA_CONFIG
  sed -i '/socket/d' $NDB_REPLICA_CONFIG
  sed -i '/skip-networking/d' $NDB_REPLICA_CONFIG
  sed -i '/performance_schema/d' $NDB_REPLICA_CONFIG
  sed -i '/thread_handling/d' $NDB_REPLICA_CONFIG
  sed -i '/innodb_log_file_size/d' $NDB_REPLICA_CONFIG
  sed -i '/innodb_io_capacity_max/d' $NDB_REPLICA_CONFIG
  sed -i '/innodb_io_capacity/d' $NDB_REPLICA_CONFIG
  echo "default-time-zone='+8:00'" >> $NDB_REPLICA_CONFIG
  echo "log-bin=mysql-bin" >> $NDB_REPLICA_CONFIG
  echo "sync_binlog=1" >> $NDB_REPLICA_CONFIG
  echo "server-id=2" >> $NDB_REPLICA_CONFIG
  echo "binlog-format=row" >> $NDB_REPLICA_CONFIG
  # Turn on GTID for ByteNDB
  echo "gtid-mode=on" >> $NDB_REPLICA_CONFIG
  echo "enforce-gtid-consistency" >> $NDB_REPLICA_CONFIG
  echo "log-slave-updates" >> $NDB_REPLICA_CONFIG
  echo "master-info-repository=TABLE" >> $NDB_REPLICA_CONFIG
  echo "relay-log-info-repository=TABLE" >> $NDB_REPLICA_CONFIG
  echo "binlog-checksum=NONE" >> $NDB_REPLICA_CONFIG
  # Disable binlog for ByteNDB
  echo "disable_log_bin" >> $NDB_REPLICA_CONFIG
  echo "replica-mode=on" >> $NDB_REPLICA_CONFIG
  echo "innodb_data_file_path=ibdata1:512M:autoextend" >> $NDB_REPLICA_CONFIG
  echo "innodb_io_capacity=6000" >> $NDB_REPLICA_CONFIG
  echo "innodb_io_capacity_max=10000" >> $NDB_REPLICA_CONFIG
  echo "innodb_file_per_table=1" >> $NDB_REPLICA_CONFIG
  echo "innodb_buffer_pool_size=1G" >> $NDB_REPLICA_CONFIG
  echo "innodb_mock_server_host=localhost:8080" >> $NDB_REPLICA_CONFIG
  echo "bind-address=0.0.0.0" >> $NDB_REPLICA_CONFIG
  echo "port=$PORT" >> $NDB_REPLICA_CONFIG
  echo "socket=/tmp/ndb.socket.$USER.replica" >> $NDB_REPLICA_CONFIG
  echo "[client]" >> $NDB_REPLICA_CONFIG
  echo "port=$PORT" >> $NDB_REPLICA_CONFIG
  echo "socket=/tmp/ndb.socket.$USER.replica" >> $NDB_REPLICA_CONFIG

  echo $MYSQLDVER
  echo "Initialize master data directory with password $NDB_DEFAULT_PASSWORD"
  mysqld --defaults-file=$NDB_PRIMARY_CONFIG --initialize --init-file=$CMDDIR/mysql8_init.sql --basedir=$NDB_BASEDIR --datadir=$PRIMARY_DATADIR
  # No need to initialize replica, just share data with primary.
  cp -R $PRIMARY_DATADIR $REPLICA_DATADIR

  # Save configuration
  echo "$PRIMARY_DATADIR" > $CMDDIR/primary.cfg
  echo "$REPLICA_DATADIR" > $CMDDIR/replica.cfg
}

function ndbattach()
{
  MYSQLD=$NDB_BASEDIR/bin/mysqld
  NDBPROC=$(ps -ef | grep $USER | grep mysqld | grep "$NDB_CONFIG" | grep -v safe | grep -v grep | awk '{print $2}')
  if [ -z "$NDBPROC" ]; then
    echo "Can't find the mysqld to be attached"
  else
    CMDFILE=$CMDDIR/loadmysql.cmd
    gdb -x $CMDFILE $MYSQLD $NDBPROC
  fi
}

function ndbattachprimary()
{
  MYSQLD=$NDB_BASEDIR/bin/mysqld
  NDBPROC=$(ps -ef | grep $USER | grep mysqld | grep "$NDB_PRIMARY_CONFIG" | grep -v safe | grep -v grep | awk '{print $2}')
  if [ -z "$NDBPROC" ]; then
    echo "Can't find the master mysqld to be attached"
  else
    gdb -x $CMDDIR/loadmysql.cmd $MYSQLD $NDBPROC
  fi
}

function ndbattachreplica()
{
  MYSQLD=$NDB_BASEDIR/bin/mysqld
  NDBPROC=$(ps -ef | grep $USER | grep mysqld | grep "$NDB_REPLICA_CONFIG" | grep -v safe | grep -v grep | awk '{print $2}')
  if [ -z "$NDBPROC" ]; then
    echo "Can't find the slave mysqld to be attached"
  else
    gdb -x $CMDDIR/loadmysql.cmd $MYSQLD $NDBPROC
  fi
}

function ndbprepare()
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

  sysbench --test=tests/db/parallel_prepare.lua --oltp_tables_count=$NDB_DEFAULT_TABLE_COUNT --mysql-db=$DBNAME --oltp-table-size=$NDB_DEFAULT_TABLE_SIZE --mysql-user=$DBUSER --mysql-password=$NDB_DEFAULT_PASSWORD --mysql-port=$DBPORT --mysql-host=$DBHOST --num-threads=$NDB_DEFAULT_TABLE_COUNT --report-interval=10 run
}

function ndbrunwrite()
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

  sysbench --test=tests/db/oltp.lua --mysql-table-engine=innodb --oltp_tables_count=$NDB_DEFAULT_TABLE_COUNT --mysql-db=$DBNAME --oltp-table-size=$NDB_DEFAULT_TABLE_SIZE --mysql-user=$DBUSER --mysql-password=$NDB_DEFAULT_PASSWORD --mysql-port=$DBPORT --mysql-host=$DBHOST --rand-type=uniform --num-threads=$CONCURRENCY --max-requests=0 --rand-seed=42 --max-time=$DURATION --oltp-read-only=off --report-interval=10 --forced-shutdown=3 run
}

function ndbrunread()
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

  sysbench --test=tests/db/oltp.lua --oltp_tables_count=$NDB_DEFAULT_TABLE_COUNT --mysql-db=$DBNAME --oltp-table-size=$NDB_DEFAULT_TABLE_SIZE --mysql-user=$DBUSER --mysql-password=$NDB_DEFAULT_PASSWORD --mysql-port=$DBPORT --mysql-host=$DBHOST --db-dirver=mysql --num-threads=$CONCURRENCY --max-requests=0 --oltp_simple_ranges=0 --oltp-distinct-ranges=0 --oltp-sum-ranges=0 --oltp-order-ranges=0 --rand-seed=42 --max-time=$DURATION --oltp-read-only=on --report-interval=10 --forced-shutdown=3 run
}

function ndbrunpurewrite()
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

  sysbench --test=tests/db/oltp.lua --mysql-table-engine=innodb --oltp_tables_count=$NDB_DEFAULT_TABLE_COUNT --mysql-db=$DBNAME --oltp-table-size=$NDB_DEFAULT_TABLE_SIZE --mysql-user=$DBUSER --mysql-password=$NDB_DEFAULT_PASSWORD --mysql-port=$DBPORT --mysql-host=$DBHOST --rand-type=uniform --num-threads=$CONCURRENCY --max-requests=0 --max-requests=0 --oltp_simple_ranges=0 --oltp-distinct-ranges=0 --oltp-sum-ranges=0 --oltp-order-ranges=0 --oltp-point-selects=0 --rand-seed=42 --max-time=$DURATION --oltp-read-only=off --report-interval=10 --forced-shutdown=3 run
}
