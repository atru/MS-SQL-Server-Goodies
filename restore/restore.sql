
SET NOCOUNT ON
	DECLARE @query varchar(max)='
	EXEC sp_configure ''show advanced options'', 1
	RECONFIGURE
	EXEC sp_configure ''xp_cmdshell'', 1
	RECONFIGURE
	'
	exec(@query)

	DECLARE @dbName varchar(100) 
	DECLARE @backupPath NVARCHAR(500) 
	DECLARE @cmd NVARCHAR(500) 
	DECLARE @dirList TABLE (backupDir NVARCHAR(255)) 
	DECLARE @fileList TABLE (id INT IDENTITY,backupFile NVARCHAR(255)) 
	DECLARE @lastFullBackup NVARCHAR(500) 
	DECLARE @backupFile NVARCHAR(500) 
	DECLARE @i INT = 1

	SET @backupPath = 'C:\backup\' 

	SET @cmd = 'DIR /a:d /b ' + @backupPath 

	INSERT INTO @dirList(backupDir) 
	EXEC master.sys.xp_cmdshell @cmd 
	DELETE FROM @dirList WHERE backupDir NOT LIKE '201%'
	
	SELECT @backupPath += MAX(ISNULL(backupDir,''))  
		FROM @dirList  
	
	SET @cmd = 'DIR /b ' + @backupPath 

	INSERT INTO @fileList(backupFile)
	EXEC master.sys.xp_cmdshell @cmd 

	DELETE FROM @fileList WHERE backupFile IS NULL

	SELECT 'USE MASTER'

	SELECT 'Declare @dbname sysname
	Declare @spid int'

	WHILE @i <= (SELECT COUNT(1) FROM @fileList) BEGIN
		SELECT @dbname = SUBSTRING(f.backupFile,1,CHARINDEX('.bak',f.backupFile)-1)
			FROM @fileList f 
			WHERE id=@i
		
		SELECT '----------------------------------------------'
		SELECT 'Set @dbname = '''+@dbname+'''
					
			Select @spid = min(spid) from master.dbo.sysprocesses
				where dbid = db_id(@dbname)
			While @spid Is Not Null
			Begin
					Execute (''Kill '' + @spid)
					Select @spid = min(spid) from master.dbo.sysprocesses
						where dbid = db_id(@dbname) and spid > @spid
			End'

		SELECT 'IF OBJECT_ID('''+SUBSTRING(f.backupFile,1,CHARINDEX('.bak',f.backupFile)-1)+''') IS NOT NULL
		ALTER DATABASE '+SUBSTRING(f.backupFile,1,CHARINDEX('.bak',f.backupFile)-1)+' SET OFFLINE WITH ROLLBACK IMMEDIATE'	
			FROM @fileList f 
			WHERE id=@i
		SELECT 'RESTORE DATABASE ' + SUBSTRING(f.backupFile,1,CHARINDEX('.bak',f.backupFile)-1) + ' FROM DISK = ''' + @backupPath +'\'+ f.backupFile + ''' WITH RECOVERY, REPLACE'
			FROM @fileList f
			WHERE id=@i
		SELECT 'ALTER DATABASE '+SUBSTRING(f.backupFile,1,CHARINDEX('.bak',f.backupFile)-1)+' SET ONLINE WITH ROLLBACK IMMEDIATE' 	
			FROM @fileList f 
			WHERE id=@i
		SET @i += 1
	END

	
	SET @query='
	EXEC sp_configure ''xp_cmdshell'', 0
	RECONFIGURE
	EXEC sp_configure ''show advanced options'', 0
	RECONFIGURE	
	'
	exec(@query)
