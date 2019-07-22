function byteformat()
{
  FORMAT=${PWD}/format.py
  if [ ! -f ${FORMAT} ]; then
    echo "Unable to locate ${FORMAT}"
    return
  fi

  git ls-files --modified --others --exclude-standard | grep -v source_downloads | grep -e "\.h" -e "\.ic" -e "\.cc" | xargs ${FORMAT}
}

function byteformatfix()
{
  FORMATFIX=${PWD}/formatfix.py
  if [ ! -f ${FORMATFIX} ]; then
    echo "Unable to locate ${FORMATFIX}"
    return
  fi

  git ls-files --modified --others --exclude-standard | grep -v source_downloads | grep -e "\.h" -e "\.ic" -e "\.cc" | xargs ${FORMATFIX}
}

function bytelint()
{
  LINT=${PWD}/lint.py
  if [ ! -f ${LINT} ]; then
    echo "Unable to locate ${LINT}"
    return
  fi

  git ls-files --modified --others --exclude-standard | grep -v source_downloads | grep "\.cc" | xargs ${LINT}
}
