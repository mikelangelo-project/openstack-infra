#!/bin/bash
BASE_DIR="$(dirname $(readlink -f $0))"
SUFFIX=$(($(date +%s%N)/1000000))
TEST_ROOT="$BASE_DIR/scenarios"
TMP_JOB_FILE=$(mktemp --tmpdir "job.XXXXXX") 
TMP_ARG_FILE=$(mktemp --tmpdir "arg.XXXXXX")
LOG_DIR="$BASE_DIR/log"

mkdir $LOG_DIR

trap "rm -rf $TMP_JOB_FILE $TMP_ARG_FILE" EXIT

echo

print_help () {
  echo "usage: task_run.sh [-h] [-t TEST_TYPE] [-g TEST_GROUP] [--task-args-file YAML_FILE]"
  echo 
}

select_main_group () {
   local _main_group=""

   _groups=($TEST_ROOT/*/)
   _counter=0

   for d in "${_groups[@]}"
   do
       _counter=$[$_counter +1]
       printf "%-5s %-30s \n" "$_counter:" $(basename $d)
   done
   
   echo ""
   read -p "Which job do you want to run? " choice

   if ((0>="$choice" || "$choice">${#_groups[@]}))
   then
       echo "$choice is a invalid choice!"
       echo "" 
       exit
   fi

   choice=$[$choice -1]
   TEST_MAIN_GROUP=${_groups[$choice]}
   TEST_MAIN_GROUP=$(basename $TEST_MAIN_GROUP)
}

select_group () {
    local _main_group=$1
    local _group=""

    shopt -s dotglob
    shopt -s nullglob
    _groups=($_main_group/*/)
    _counter=1

    printf "%-5s %-30s \n" "1:" "all"
    for d in "${_groups[@]}"
    do  
        _counter=$[$_counter +1]
        printf "%-5s %-30s \n" "$_counter:" $(basename $d)
    done
    echo ""
    read -p "Which job do you want to run? " choice

    _length=${#_groups[@]}
    _length=$[$_length +1]

    if ((0>="$choice" || "$choice">$_length))
    then
        echo "$choice is a invalid choice!"
        echo "" 
        exit
    fi

    if (("$choice"==1))
    then
        TEST_GROUP="all"
    else
        choice=$[$choice -2]
        TEST_GROUP=${_groups[$choice]}
        TEST_GROUP=$(basename $TEST_GROUP)
    fi
}

while [[ $# > 0 ]]
do
  key="$1"

  case $key in
    -h|--help)
    print_help
    exit
    shift
    ;;
    -t|--type)
    if [ -z "$2" ]; then
      echo "Missing value for -t|-type"
      exit 
    fi
    TEST_MAIN_GROUP="$2"
    shift
    ;;
    -g|--group)
    TEST_GROUP="$2"
    if [ -z "$2" ]; then
      echo "Missing value for -g|-group"
      exit 
    fi
    print_help
    shift
    ;;
    --task-args-file)
    TEST_ARGS_FILE="$2"
    if [ -z "$2" ]; then
      echo "Missing value for --task-args-file"
      exit 
    fi
    shift
    ;;
    *)
    print_help 
    exit
    ;;
  esac
  shift
done

if [ -z "$TEST_MAIN_GROUP" ]; then
    echo "Select scenario type:"
    echo 
    select_main_group
fi

echo ""

if [ -z "$TEST_GROUP" ]; then
    echo "Select scenario group:"
    echo 
    select_group "$TEST_ROOT/$TEST_MAIN_GROUP"
fi

JOB="$TEST_MAIN_GROUP-$TEST_GROUP"
CURRENT_TEST_NAME="job-$JOB-$SUFFIX"

if [ "$TEST_GROUP" == "all" ]; then
    TEST_GROUP="$TEST_ROOT/$TEST_MAIN_GROUP"
else
    TEST_GROUP="$TEST_ROOT/$TEST_MAIN_GROUP/$TEST_GROUP"
fi

TEST_FILES=$(find $TEST_GROUP -iregex '.*\(yaml\)' -follow -print)

echo "collect scenario args:"
if [ -z "$TEST_ARGS_FILE" ]; then
  TEST_ARGS_FILE="$TEST_ROOT/$TEST_MAIN_GROUP/args.conf"
else
  if [ ! -f "$TEST_ARGS_FILE" ]   
  then
    echo "File $TEST_ARGS_FILE not found!" >&2   
    exit 86
  fi 
fi


echo "---" > "$TMP_ARG_FILE"
cat "$TEST_ARGS_FILE" >> "$TMP_ARG_FILE"

echo "---" > "$TMP_JOB_FILE"
echo "collect scenarios:"

for f in $TEST_FILES
do
    echo " * $f"
    echo >> "$TMP_JOB_FILE"
    cat $f >> "$TMP_JOB_FILE"
done

echo ""
echo "RUN: task start job"
rally --verbose --debug task start "$TMP_JOB_FILE" --tag $CURRENT_TEST_NAME --task-args-file "$TMP_ARG_FILE"  > "$LOG_DIR/$CURRENT_TEST_NAME.log" 2>&1 &

sleep 3

PID=$!

if ps -p $PID > /dev/null
then
    echo "Job is running"
else
    cat "$LOG_DIR/$CURRENT_TEST_NAME.log"
    exit 1
fi

echo "DETAIL:"
echo 
rally task detailed

echo ""
echo "LIST RUNNING JOBS:"
echo
rally task list

echo ""
echo "HINTS:"
echo " * List tasks:"
echo "      rally task list"
echo " * Show details for the task:"
echo "      rally task detailed"
echo ""
