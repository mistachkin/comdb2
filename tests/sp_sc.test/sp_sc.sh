#!/usr/bin/env bash

[[ -n "$3" ]] && exec >$3 2>&1
cdb2sql $SP_OPTIONS - <<EOF
create table t1 {$(cat t.csc2)}\$\$
create table foraudit {$(cat foraudit.csc2)}\$\$
create procedure dml0 version 'dml0test' {$(cat begin_select.lua)}\$\$
create procedure dml1 version 'dml1test' {$(cat begin_insert.lua)}\$\$
create lua consumer dml0 on (table foraudit for insert)
create lua consumer dml1 on (table foraudit for insert)
EOF

cdb2sql $SP_OPTIONS "insert into t1 values('outer t1');"

for ((i=1;i<100;++i)); do
    echo "insert into foraudit values(${i})"
done | cdb2sql $SP_OPTIONS - >/dev/null

for ((i=1;i<100;++i)); do
    ./sp_sc_create_table.sh $((i + 1)) &
    cdb2sql --host $SP_HOST $SP_OPTIONS "exec procedure dml1(${i})" &
done
wait

for ((i=1;i<100;++i)); do
    ./sp_sc_create_table.sh $((i + 201)) &
    cdb2sql --host $SP_HOST $SP_OPTIONS "exec procedure dml0(${i})"
done
wait

cdb2sql $SP_OPTIONS "select count(*) from sqlite_master where type = 'table' and name like 't%';"
cdb2sql $SP_OPTIONS "select 'post', s from t1 order by cast(s as integer);"
cdb2sql $SP_OPTIONS "select queuename, depth from comdb2_queues order by queuename;"
