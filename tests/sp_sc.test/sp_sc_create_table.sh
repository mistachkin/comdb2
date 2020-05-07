#!/usr/bin/env bash

cdb2sql $SP_OPTIONS - <<EOF &
create table t$1 {$(cat t.csc2)}\$\$
EOF
