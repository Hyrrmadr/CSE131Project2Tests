#!/bin/sh

#f_diff="--unified=30" # Damn you SPARC diff

display_error()
{
    if [ $1 -eq $ERR_USAGE ]; then
      if [ "$2" != "" ]; then
        echo "Error: $2"
      fi
    	echo "Usage: test.sh [-cdh] dir"
      echo "\t-c\tuse Makefile rule 'compile_custom' instead of 'compile' (has to be setup ahead)"
      echo "\t-d\tuse RCdbg instead of RC"
      echo "\t-h\tprint this message"
      echo "\tdir\tgive the directory to correct"
    elif [ $1 -eq $ERR_TEST ]; then
      echo "Cannot find directory with tests : $tests"
    elif [ $1 -eq $ERR_DIRECTORY ]; then
      echo "Cannot find directory to correct : $bindir"
    elif [ $1 -eq $ERR_BINARY ]; then
      echo "Cannot find binary to correct : $bin"
    elif [ $1 -eq $ERR_NOTEST ]; then
      echo "Cannot find any test in directory to correct : $tests"
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
  t="$old_path"

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

  files=""

  good=2
  list=("$tests/*.output")
  for lit in $list; do
    if [ $good -eq 2 ]; then
      good=1
    fi
    blit=$(basename "$lit")
    blit="${blit%.*}"
    if [ ! -f "$tests/$blit.rc" ]; then
      good=0
      echo "Missing file : $tests/$blit.rc"
    fi
    files="$files $tests/$blit"
  done

  if [ $good -eq 2 ]; then
      display_error $ERR_NOTEST
  elif [ $good -ne 1 ]; then
      display_error $ERR_EXIT
  fi

  good_compile="$tests/good_compile"

  rule='compile'
  if [ $c -eq 1 ]; then
    rule='compile_custom'
  fi

  count_good=0
  count_total=0

  for fle in $files; do
    count_total=$((count_total + 1))

    src="$fle.rc"
    output="$fle.output"
    compile="$good_compile"
    if [ -f "$fle.compile" ]; then
      compile="$fle.compile"
    fi

    echo "--- Testing $src ---"

    "$bin" "$src" | grep -v "^Error" | diff $f_diff /dev/stdin "$compile"
    result=$?
    if [ $result -eq 0 ]; then
      if [ "$compile" == "$good_compile" ]; then
        make -s -C "$bindir" $rule

        result=$?
        if [ $result -eq 0 ]; then
          ./a.out | diff $f_diff /dev/stdin "$output"

          result=$?
          if [ $result -eq 0 ]; then
            echo "$m_good"
            count_good=$((count_good + 1))
          else
            echo "$m_bad"
          fi
        else
          echo "$m_mbad"
        fi
      else
        echo "$m_good"
        count_good=$((count_good + 1))
      fi
    else
      echo "$m_cbad"
    fi

    echo ""
  done

  echo "RESULT: $count_good / $count_total"

  cd "$old_path"

  if [ $count_good -ne $count_total ]; then
    exit 1
  fi
}

ERR_EXIT=0
ERR_USAGE=1
ERR_TEST=2
ERR_DIRECTORY=3
ERR_NOTEST=4
ERR_BINARY=5

m_begin="--- "
m_end=" ---"
m_good="${m_begin}GOOD${m_end}"
m_bad="\n< Yours\n> Correction\n${m_begin}BAD${m_end}"
m_cbad="\n< Yours\n> Correction\n${m_begin}COMPILATION BAD${m_end}"
m_mbad="${m_begin}MAKE BAD${m_end}"

c=0
h=0
dg=0
d=""
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
      display_error $ERR_USAGE "Too much arguments"
    fi
    d="$1"
    shift
  fi
done

if [ "$d" == "" ]; then
  display_error $ERR_USAGE "Missing argument for: dir"
fi

launch
