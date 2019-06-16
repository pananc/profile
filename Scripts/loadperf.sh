function perflist()
{
  perf list
}

function perfstat()
{
  PROGNAME=$1
  if [ -z "$PROGNAME" ]; then
    echo "Usage: perfstat <progname> [<duration>]"
    return
  fi
  DURATION=$2
  if [ -z $DURATION ]; then
    sudo perf stat -p `pidof -s $PROGNAME`
  else
    sudo perf stat -p `pidof -s $PROGNAME` sleep $DURATION
  fi
}

function perfstatthread()
{
  THREADID=$1
  if [ -z "$THREADID" ]; then
    echo "Usage: perfstatthread <tid> [<duration>]"
    return
  fi
  DURATION=$2
  if [ -z $DURATION ]; then
    sudo perf stat -t $THREADID
  else
    sudo perf stat -t $THREADID sleep $DURATION
  fi
}

function perftop()
{
  PROGNAME=$1
  if [ -z "$PROGNAME" ]; then
    sudo perf top
  else
    sudo perf top -p `pidof -s $PROGNAME`
  fi
}

function perftopthread()
{
  THREADID=$1
  if [ -z "$THREADID" ]; then
    sudo perf top
  else
    sudo perf top -t $THREADID
  fi
}

function perfrecord()
{
  PROGNAME=$1
  if [ -z "$PROGNAME" ]; then
    echo "Usage: perfrecord <progname> [<duration>]"
        return
  fi
  DURATION=$2
  rm -f $REPORTDIR/perf.data
  if [ -z $DURATION ]; then
    perf record -F 99 -a -g -p `pidof -s $PROGNAME` -o $REPORTDIR/perf.data
  else
    perf record -F 99 -a -g -p `pidof -s $PROGNAME` -o $REPORTDIR/perf.data -- sleep $DURATION
  fi
}

function perfrecordthread()
{
  THREADID=$1
  if [ -z "$THREADID" ]; then
    echo "Usage: perfrecordthread <tid> [<duration>]"
    return
  fi
  DURATION=$2
  rm -f $REPORTDIR/perf.data
  if [ -z $DURATION ]; then
    perf record -F 99 -a -g -t $THREADID -o $REPORTDIR/perf.data
  else
    perf record -F 99 -a -g -t $THREADID -o $REPORTDIR/perf.data -- sleep $DURATION
  fi
}

function perfreport()
{
  TAG=$1
  TIMESTAMP=$(date +%Y_%m_%d_%H_%M_%S)
  if [ -z $TAG ]; then
    FLATREPORTFILE=$REPORTDIR/"${TIMESTAMP}_flat.report"
    GRAPHREPORTFILE=$REPORTDIR/"${TIMESTAMP}_graph.report"
    FRACTALREPORTFILE=$REPORTDIR/"${TIMESTAMP}_fractal.report"
    CSVREPORTFILE=$REPORTDIR/"${TIMESTAMP}.csv"
  else
    FLATREPORTFILE=$REPORTDIR/"${TAG}_${TIMESTAMP}_flat.report"
    GRAPHREPORTFILE=$REPORTDIR/"${TAG}_${TIMESTAMP}_graph.report"
    FRACTALREPORTFILE=$REPORTDIR/"${TAG}_${TIMESTAMP}_fractal.report"
    CSVREPORTFILE=$REPORTDIR/"${TAG}_${TIMESTAMP}.csv"
  fi

  echo "Generating $FLATREPORTFILE"
  perf report -i $REPORTDIR/perf.data -g flat,0.5 > $FLATREPORTFILE
  echo "Generating $GRAPHREPORTFILE"
  perf report -i $REPORTDIR/perf.data -g graph,0.5 > $GRAPHREPORTFILE
  echo "Generating $FRACTALREPORTFILE"
  perf report -i $REPORTDIR/perf.data -g fractal,0.5 > $FRACTALREPORTFILE
  echo "Generating $CSVREPORTFILE"
  echo "Overhead,Command,Shared Object,Symbol" > $CSVREPORTFILE
  perf report -i $REPORTDIR/perf.data -T -t , | grep "," | grep -v "#" >> $CSVREPORTFILE
}

function perfscript()
{
  TAG=$1
  TIMESTAMP=$(date +%Y_%m_%d_%H_%M_%S)
  if [ -z $TAG ]; then
    PREFIX=${TIMESTAMP}
  else
    PREFIX=${TAG}_${TIMESTAMP}
  fi

  if [ ! -d $HOME/FlameGraph ]; then
    echo "Unable to locate $HOME/FlameGraph"
    return
  fi

  echo "Generating ${PREFIX}.perf"
  perf script -i $REPORTDIR/perf.data > $REPORTDIR/${PREFIX}.perf
  echo "Generating ${PREFIX}.folded"
  $HOME/FlameGraph/stackcollapse-perf.pl $REPORTDIR/${PREFIX}.perf > $REPORTDIR/${PREFIX}.folded
  echo "Generating ${PREFIX}.svg"
  $HOME/FlameGraph/flamegraph.pl $REPORTDIR/${PREFIX}.folded > $REPORTDIR/${PREFIX}.svg
}
