#!/usr/bin/env bash

# Remote cursor moves testcase for comdb2
################################################################################


# args
# <dbname> <autodbname> <dbdir> <testdir>
a_remdbname=$1
a_remcdb2config=$2
#srcdb:
a_dbname=$3
a_cdb2config=$4

set -e

output="output.log"
cmd_rmt="cdb2sql -s --cdb2cfg ${a_remcdb2config} $a_remdbname default -" 
cmd="cdb2sql -s --cdb2cfg ${a_cdb2config} $a_dbname default " 

echo "Inserting rows"
$cmd_rmt < inserts.req > ${output} 2>&1

#populate remote schema in the local db
echo "Select from remote db"
$cmd "select * from LOCAL_${a_remdbname}.t" >> ${output} 2>&1

# we expect errors here
set +e
echo "Trying to skip LOCAL override"
# this should fail for missing LOCAL
$cmd "select * from ${a_remdbname}.t" >> ${output} 2>&1

# this should fail for missing dbname 
echo "Trying to skip dbname"
$cmd "select * from t" >> ${output} 2>&1

set -e
# proper access, test old db with new table
echo "Accessing same remote db but new table"
$cmd "select * from LOCAL_${a_remdbname}.t2" >> ${output} 2>&1

# proper access, test old db and old table
echo "Accessing again same db, and same old table"
$cmd "select * from LOCAL_${a_remdbname}.t" >> ${output} 2>&1


# get testcase output
echo "Comparing output"
testcase_output=$(cat $output)

# get expected output
sed "s/ remdb/ ${a_remdbname}/g" $output.exp.src > $output.exp
expected_output=$(cat $output.exp)

# verify 
if [[ "$testcase_output" != "$expected_output" ]]; then

    echo "  ^^^^^^^^^^^^"
    echo "The above testcase (${testcase}) has failed!!!"
    echo " "
    echo "Use 'diff <expected-output> <my-output>' to see why:"
    echo "> diff ${PWD}/{$output.exp,$output}"
    echo " "
    diff $output.exp $output
    echo " "
    exit 1

fi

echo "Testcase passed."
