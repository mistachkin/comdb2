#!/usr/bin/env bash

[[ -n "$3" ]] && exec >$3 2>&1
cdb2sql $SP_OPTIONS - <<EOF
create table t1 {$(cat t.csc2)}\$\$
create procedure dml0 version 'dml0test' {$(cat begin_select.lua)}\$\$
create procedure dml1 version 'dml1test' {$(cat begin_insert.lua)}\$\$
EOF

cdb2sql $SP_OPTIONS "insert into t1 values('outer t1');"

for ((i=2;i<100;++i)); do
cdb2sql $SP_OPTIONS - <<EOF &
create table t${i} {$(cat t.csc2)}\$\$
EOF
done
wait

cdb2sql $SP_OPTIONS "select name from sqlite_master where type = 'table' and name like 't%' order by name;"

for ((i=1;i<1000;++i)); do
    echo "exec procedure dml1(${i})"
done | cdb2sql --host $SP_HOST $SP_OPTIONS - >/dev/null &
wait

for ((i=1;i<1000;++i)); do
    echo "exec procedure dml0(${i})"
done | cdb2sql --host $SP_HOST $SP_OPTIONS -

cdb2sql $SP_OPTIONS "select 'post', s from t1 order by cast(s as integer);"
