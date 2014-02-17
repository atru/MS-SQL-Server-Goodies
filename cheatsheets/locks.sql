SELECT DISTINCT request_mode,
      name AS database_name,
      session_id,
      host_name,
      login_time,
      login_name,
      reads,
      writes
 FROM sys.dm_exec_sessions
 LEFT OUTER JOIN sys.dm_tran_locks ON sys.dm_exec_sessions.session_id = sys.dm_tran_locks.request_session_id
 INNER JOIN sys.databases ON sys.dm_tran_locks.resource_database_id = sys.databases.database_id
 WHERE resource_type <> 'DATABASE'
 AND request_mode LIKE '%X%' --EXCULSIVE LOCK
 --AND name ='YourDatabaseNameHere'
 ORDER BY name