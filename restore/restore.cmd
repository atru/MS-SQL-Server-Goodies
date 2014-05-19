sqlcmd -h -1 -S .\INSTANCE -U usr -P pwd -i restore.sql -m 11 -o restore_run.sql
sqlcmd -S .\INSTANCE -U usr -P pwd -i restore_run.sql
pause
