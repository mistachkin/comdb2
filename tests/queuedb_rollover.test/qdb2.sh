#!/usr/bin/env bash

[[ -n "$3" ]] && exec >$3 2>&1
cdb2sql $SP_OPTIONS - <<EOF
create table foraudit2 {$(cat foraudit.csc2)}\$\$
create procedure nop1 version 'noptest' {$(cat nop_consumer.lua)}\$\$
create lua consumer nop1 on (table foraudit2 for insert and update and delete)
EOF

./qdb2_adds.sh 9600 &
sleep 10

cdb2sql $SP_OPTIONS "select (depth > 0) as hasDepth from comdb2_queues where queuename = '__qnop1';"

./qdb2_cons.sh 9600 &
sleep 10

cdb2sql $SP_OPTIONS "select (depth > 0) as hasDepth from comdb2_queues where queuename = '__qnop1';"

for ((i=0;i<10;++i)); do
    for ((j=0;j<3;++j)); do
        ./qdb2_adds.sh 96 &
        ./qdb2_cons.sh 96 &
    done
    wait
    cdb2sql $SP_OPTIONS "select depth from comdb2_queues where queuename = '__qnop1';"
done

cdb2sql $SP_OPTIONS "select depth from comdb2_queues where queuename = '__qnop1';"
cdb2sql $SP_OPTIONS "select count(*) as row_count from foraudit2;"
