#!/bin/bash

shopt -s nullglob

display_error()
{
  if [ $1 -eq $ERR_USAGE ]; then
    if [ "$2" != "" ]; then
      echo "Error: $2"
    fi
    echo "Usage: compile.sh [-cdh] dir file [flags]"
    echo -e "\t-c\tuse Makefile rule 'compile_custom' instead of 'compile' (has to be setup ahead)"
    echo -e "\t-d\tuse RCdbg instead of RC"
    echo -e "\t-h\tprint this message"
    echo -e "\tdir\tgive the directory to correct"
    echo -e "\tfile\tgive the file to compile"
  elif [ $1 -eq $ERR_TEST ]; then
    echo "Cannot find directory with tests : $tests"
  elif [ $1 -eq $ERR_DIRECTORY ]; then
    echo "Cannot find directory to correct : $bindir"
  elif [ $1 -eq $ERR_BINARY ]; then
    echo "Cannot find file to compile : $bin"
  fi
  exit 1
}

launch()
{
  if [ $h -eq 1 ]; then
    display_error $ERR_USAGE
  fi

  bindir="$d"
  if [ ! -d "$bindir" ]; then
    display_error $ERR_DIRECTORY
  fi

  old_path="`pwd`"
  cd "$bindir"
  bindir=.

  if [ "${t:0:1}" != "/" ]; then
    t="$old_path"
  fi

  binname='RC'
  if [ $dg -eq 1 ]; then
    binname='RCdbg'
  fi

  bin="$bindir/$binname"
  if [ ! -f "$bin" ]; then
    display_error $ERR_BINARY
  fi

  tests="$t/tests"
  if [ ! -d "$tests" ]; then
    display_error $ERR_TEST
  fi

  rule='compile'
  if [ $c -eq 1 ]; then
    rule='compile_custom'
  fi

  name="$f"
  if [ ! -f "$tests/$name.rc" ]; then
    display_error $ERR_NOFILE
  fi

  src="$tests/$name.rc"
  externs=""
  externs_l=("$tests/$name.*.c")
  for ext in $externs_l; do
    externs="$externs $ext"
  done

  echo "--- Testing $src ---"

  "$bin" "$src"
  result=$?
  if [ $result -eq 0 ]; then
    make -s -C "$bindir" $rule LINKOBJ="$flgs $externs"

    result=$?
    if [ $result -eq 0 ]; then
      echo "$m_good"
    else
      echo "$m_mbad"
    fi
  else
    echo "$m_cbad"
  fi

  cd "$old_path"
}

ERR_EXIT=0
ERR_USAGE=1
ERR_TEST=2
ERR_DIRECTORY=3
ERR_BINARY=4
ERR_NOFILE=5

m_begin="--- "
m_end=" ---"
m_good="${m_begin}GOOD${m_end}"
m_cbad="${m_begin}COMPILATION BAD${m_end}"
m_mbad="${m_begin}MAKE BAD${m_end}"

c=0
h=0
dg=0
d=""
f=""
flgs=""
t="${0%/*}"

while [ "$1" ]; do
  if [ "${1:0:1}" == "-" -a \( "${1#*h}" != "$1" -o "${1#*c}" != "$1" -o "${1#*d}" != "$1" \) ]; then
    if [ "${1#*c}" != "$1" ]; then
      c=1
    fi
    if [ "${1#*h}" != "$1" ]; then
      h=1
    fi
    if [ "${1#*d}" != "$1" ]; then
      dg=1
    fi
    shift
  else
    if [ "$d" != "" ]; then
      if [ "$f" != "" ]; then
        if [ "$flgs" != "" ]; then
          display_error $ERR_USAGE "Too much arguments"
        else
          flgs="$1"
        fi
      else
        f="$1"
      fi
    else
      d="$1"
    fi
    shift
  fi
done

if [ "$d" == "" ]; then
  display_error $ERR_USAGE "Missing argument for: dir"
fi

if [ "$f" == "" ]; then
  display_error $ERR_USAGE "Missing argument for: file"
fi

launch
