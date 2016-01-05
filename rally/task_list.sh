#!/bin/bash
BASE_DIR="$(dirname $(readlink -f $0))"
SUFFIX=$(date +"%Y%m%d")

TEST_ROOT="$BASE_DIR/scenarios"

if (( $# > 0 ))
then
   TEST_MAIN_GROUP=$1
   echo ""
   echo "Groups in $TEST_MAIN_GROUP:"
   echo ""
   TEST_GROUPS=$(find $TEST_ROOT/$TEST_MAIN_GROUP -maxdepth 1 -type d)
   delete="$TEST_ROOT/$TEST_MAIN_GROUP"
else
   echo ""
   echo "use ./task_list.sh <test_group> do see more detail."
   echo ""
   TEST_GROUPS=$(find $TEST_ROOT -maxdepth 1 -type d)
   delete=$TEST_ROOT
fi

TEST_GROUPS=("${TEST_GROUPS[@]/$delete}")

for d in $TEST_GROUPS
do
    printf "%-30s %-30s \n" $(basename $d) "use ./task_run.sh $TEST_MAIN_GROUP $(basename $d)"
done

echo ""
