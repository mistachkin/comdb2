#!/usr/bin/env bash

for ((k=0;k<$1;++k)); do
    cdb2sql $SP_OPTIONS "drop table foraudit3" 2>&1 >/dev/null
    cdb2sql $SP_OPTIONS "create table foraudit3 {$(cat foraudit.csc2)}" 2>&1 >/dev/null
done
