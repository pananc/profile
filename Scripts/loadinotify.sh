function inwait()
{
  DIR=$1
  if [ -z $DIR ]; then
    DIR=$PWD
  fi

  DURATION=$2 # in seconds
  if [ -z $DURATION ]; then
    inotifywait -m -r --timefmt '%Y-%m-%d %H:%M:%S' --format '[%T] %w: %:e %f' $DIR
  else
    inotifywait -m -r -t $DURTION --timefmt '%Y-%m-%d_%H:%M:%S' --format '[%T] %w: %:e %f' $DIR
  fi
}

function inwatch()
{
  DIR=$1
  if [ -z $DIR ]; then
    DIR=$PWD
  fi

  DURATION=$2 # in seconds
  if [ -z $DURATION ]; then
    inotifywatch -v -r $DIR
  else
    inotifywatch -v -t $DURATION -r $DIR
  fi
}
