#!/usr/bin/env bash

cdb2sql --host $SP_HOST $SP_OPTIONS "EXEC PROCEDURE sys.cmd.send('free_ruleset')"
cdb2sql --host $SP_HOST $SP_OPTIONS "EXEC PROCEDURE sys.cmd.send('free_ruleset')"
cdb2sql --host $SP_HOST $SP_OPTIONS "EXEC PROCEDURE sys.cmd.send('dump_ruleset')"

cdb2sql --host $SP_HOST $SP_OPTIONS "SELECT 1;" 2>&1
cdb2sql --host $SP_HOST $SP_OPTIONS "SELECT * FROM t1;" 2>&1
cdb2sql --host $SP_HOST $SP_OPTIONS "SELECT comdb2_ctxinfo('priority'), x FROM t1;" 2>&1 | sed 's/=[0-9][0-9]/=xx/g'
cdb2sql --host $SP_HOST $SP_OPTIONS "SELECT x FROM t1 ORDER BY x;" 2>&1

cdb2sql --host $SP_HOST $SP_OPTIONS "PUT TUNABLE 'debug.thdpool_queue_only' 1"
cdb2sql --host $SP_HOST $SP_OPTIONS "PUT TUNABLE 'debug.force_thdpool_priority' 1"
cdb2sql --host $SP_HOST $SP_OPTIONS "EXEC PROCEDURE sys.cmd.send('reload_ruleset $DBDIR/rulesets/t01.ruleset')" | sed 's/file ".*"/file "t01.ruleset"/g'
cdb2sql --host $SP_HOST $SP_OPTIONS "EXEC PROCEDURE sys.cmd.send('dump_ruleset')" | sed 's/ruleset 0x[0-9A-Fa-f]\+/ruleset 0x00000000/g'

cdb2sql --host $SP_HOST $SP_OPTIONS "SELECT 2;" 2>&1
cdb2sql --host $SP_HOST $SP_OPTIONS "SELECT * FROM t1;" 2>&1
cdb2sql --host $SP_HOST $SP_OPTIONS "SELECT comdb2_ctxinfo('priority'), x FROM t1;" 2>&1 | sed 's/=[0-9][0-9][0-9][0-9][0-9][0-9]/=yyyy/g'
cdb2sql --host $SP_HOST $SP_OPTIONS "SELECT x FROM t1 ORDER BY x;" 2>&1
cdb2sql --host $SP_HOST $SP_OPTIONS "CREATE TABLE txx(bad TEXT);" 2>&1

cdb2sql --host $SP_HOST $SP_OPTIONS "EXEC PROCEDURE sys.cmd.send('save_ruleset $DBDIR/rulesets/t01_saved.ruleset')" | sed 's/file ".*"/file "t01_saved.ruleset"/g'
cdb2sql --host $SP_HOST $SP_OPTIONS "EXEC PROCEDURE sys.cmd.send('save_ruleset $DBDIR/rulesets/t02_saved.ruleset')" | sed 's/file ".*"/file "t02_saved.ruleset"/g'

if [ $SP_HOST != `hostname` ]; then
  scp $SP_HOST:$DBDIR/rulesets/t01_saved.ruleset $DBDIR/rulesets/t01_saved.ruleset
  scp $SP_HOST:$DBDIR/rulesets/t02_saved.ruleset $DBDIR/rulesets/t02_saved.ruleset
fi

if ! diff $DBDIR/rulesets/t01.ruleset $DBDIR/rulesets/t01_saved.ruleset ; then
  echo output for t01_saved.ruleset is different from expected
  exit 1
fi

if ! diff $DBDIR/rulesets/t01.ruleset $DBDIR/rulesets/t02_saved.ruleset ; then
  echo output for t02_saved.ruleset is different from expected
  exit 1
fi

cdb2sql --host $SP_HOST $SP_OPTIONS "EXEC PROCEDURE sys.cmd.send('evaluate_ruleset')" | sed 's/ruleset 0x[0-9A-Fa-f]\+/ruleset 0x00000000/g'
cdb2sql --host $SP_HOST $SP_OPTIONS "EXEC PROCEDURE sys.cmd.send('reload_ruleset $DBDIR/rulesets/t00.ruleset')" | sed 's/file ".*"/file "t00.ruleset"/g'
cdb2sql --host $SP_HOST $SP_OPTIONS "EXEC PROCEDURE sys.cmd.send('dump_ruleset')" | sed 's/ruleset 0x[0-9A-Fa-f]\+/ruleset 0x00000000/g'
cdb2sql --host $SP_HOST $SP_OPTIONS "EXEC PROCEDURE sys.cmd.send('free_ruleset')"

cdb2sql --host $SP_HOST $SP_OPTIONS "SELECT 3;" 2>&1
cdb2sql --host $SP_HOST $SP_OPTIONS "SELECT * FROM t1;" 2>&1
cdb2sql --host $SP_HOST $SP_OPTIONS "SELECT comdb2_ctxinfo('priority'), x FROM t1;" 2>&1 | sed 's/=[0-9][0-9]/=zz/g'
cdb2sql --host $SP_HOST $SP_OPTIONS "SELECT x FROM t1 ORDER BY x;" 2>&1

cdb2sql --host $SP_HOST $SP_OPTIONS "EXEC PROCEDURE sys.cmd.send('evaluate_ruleset')"
cdb2sql --host $SP_HOST $SP_OPTIONS "EXEC PROCEDURE sys.cmd.send('reload_ruleset $DBDIR/rulesets/t01.ruleset')" | sed 's/file ".*"/file "t01.ruleset"/g'
cdb2sql --host $SP_HOST $SP_OPTIONS "EXEC PROCEDURE sys.cmd.send('reload_ruleset $DBDIR/rulesets/bad.ruleset')" 2>&1 | sed 's/\[ERROR\] .*bad.ruleset/\[ERROR\] bad.ruleset/g'
cdb2sql --host $SP_HOST $SP_OPTIONS "EXEC PROCEDURE sys.cmd.send('evaluate_ruleset')" | sed 's/ruleset 0x[0-9A-Fa-f]\+/ruleset 0x00000000/g'
cdb2sql --host $SP_HOST $SP_OPTIONS "EXEC PROCEDURE sys.cmd.send('dump_ruleset')" | sed 's/ruleset 0x[0-9A-Fa-f]\+/ruleset 0x00000000/g'
