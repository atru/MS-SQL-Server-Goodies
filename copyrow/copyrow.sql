USE [SYSDB]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/**@file Copy a row in any table */
/**@author Alex Truman*/
/**@code
EXEC SYSDB.dbo._CopyRow @tableFullName='AdventureWorks2008.SalesLT.Product',@keyID=999,@todo=NULL,@keyIDout=@newKeyID OUT

DECLARE @newKeyID bigint, @newid varchar(36)=NEWID()
DECLARE @todo varchar(1000)='rowguid='+@newid+';name=Just came up;productnumber=JKU-2014'
SELECT * FROM AdventureWorks2008.SalesLT.Product WHERE ProductID=999
EXEC SYSDB.dbo._CopyRow @tableFullName='AdventureWorks2008.SalesLT.Product',@keyID=999,@todo=@todo,@keyIDout=@newKeyID OUT
SELECT * FROM AdventureWorks2008.SalesLT.Product WHERE ProductID=@newKeyID
@endcode*/
CREATE PROCEDURE [dbo].[_CopyRow]
	@tableFullName varchar(1000)		/**@param Full table name (AdventureWorks2008.SalesLT.Product)*/
	,@keyID			bigint				/**@param Source row ID (identity value)*/
	,@keyIDout		bigint=null out		/**@param Returned value of inserted identity*/
	,@todo			varchar(max)=null	/**@param String of values to change (col1=2;col2=;col3=newval)*/
AS
BEGIN
set nocount on;
	DECLARE @dbname		varchar(30)
	DECLARE @query		nvarchar(max)
	DECLARE @columns	varchar(max)
	DECLARE @key_column	varchar(100)
	DECLARE @is_identity	int
	DECLARE @tmp		varchar(100)
	DECLARE @errDesc	varchar(max)

	SET @dbname = SYSDB.dbo.arrayAt(@tableFullName,0,'.')

	IF NOT EXISTS(select 1 from sys.databases AS db WHERE db.name=isnull(@dbname,''))BEGIN
		SELECT 'Database not found'
		RETURN END
	/*********** full description of the table columns **************************************/
	CREATE TABLE #tmp_bfColumn([db] [varchar](32) NOT NULL,[object_id] [int] NOT NULL,[name] [sysname] NULL,[type] [sysname] NOT NULL,
		[column_id] [int] NOT NULL,[is_nullable] [bit] NULL,[is_identity] [bit] NOT NULL,[length] [varchar](10) NULL,[precision] [varchar](10) NULL,
		[StrLen] [smallint] NOT NULL,[LITERAL_PREFIX] [varchar](32) NULL,[LITERAL_SUFFIX] [varchar](32) NULL,[primary_key] [varchar](1) NULL)
	INSERT INTO #tmp_bfColumn([db],[object_id],[name],[type],[column_id],[is_nullable],[is_identity],[length],[precision],[StrLen],[LITERAL_PREFIX],[LITERAL_SUFFIX],[primary_key]) 
		SELECT [db],[object_id],[name],[type],[column_id],[is_nullable],[is_identity],[length],[precision],[StrLen],[LITERAL_PREFIX],[LITERAL_SUFFIX],[primary_key] 
			FROM SYSDB.._table_schemas
		WHERE [OBJECT_ID]=OBJECT_ID(@tableFullName) AND db=@dbname

	SELECT @columns = SYSDB.dbo.list(distinct v.name,',') FROM #tmp_bfColumn as v WHERE [name] not in('InsTime','UpdTime','other unwanted columns') and v.is_identity<>1 and v.type<>'sysname'

	SELECT @key_column = v.name FROM #tmp_bfColumn as v WHERE v.primary_key='Y' OR v.is_identity=1

	BEGIN TRY
		BEGIN TRAN linecopy
		IF LEN(@columns)=0 OR ISNULL(@key_column,'')='' BEGIN
			ROLLBACK TRAN
			SELECT 'The table does not exist or it does not have identity/primary key'
			RETURN END		

		/*********** column names and suffixes/prefixes **************************************/
		CREATE TABLE #tmp_col (_name varchar(max), LITERAL_PREFIX varchar(10), LITERAL_SUFFIX varchar(10))
		INSERT INTO #tmp_col (_name, LITERAL_PREFIX, LITERAL_SUFFIX) SELECT v.name as _name, d.LITERAL_PREFIX , d.LITERAL_SUFFIX 
			FROM #tmp_bfColumn as v JOIN SYSDB.._datatype_info AS d ON (v.type=d.TYPE_NAME)
		
		/*********** split @todo from 'a=1;b=text;c=3' into table (col,colvalue) *************/

		CREATE TABLE #new_values(value varchar(4000), col varchar(100), colval varchar(4000))
		INSERT INTO #new_values(value) SELECT Match FROM SYSDB.dbo.RegExSplit(@todo,';',0)
		IF @@TRANCOUNT=0 RETURN
		/*********** split pairs 'a=1' into two columns: name and value **********************/
		UPDATE #new_values SET col=left(value,CHARINDEX('=',value)-1), colval=STUFF(value,1,CHARINDEX('=',value),'')
		UPDATE #new_values SET colval = (case WHEN colval='NULL' THEN 'NULL' ELSE ISNULL(#tmp_col.LITERAL_PREFIX,'')+colval+ ISNULL(#tmp_col.LITERAL_SUFFIX,'') END)
			FROM #tmp_col WHERE #tmp_col._name=#new_values.col	
		/*********** all columns with new values *********************************************/
		CREATE TABLE #t_all(value varchar(4000), col varchar(100), colval varchar(4000))
		INSERT INTO #t_all(value) SELECT Match FROM SYSDB.dbo.RegExSplit(@columns,',',0)
		IF @@TRANCOUNT=0 RETURN	
		update #t_all set colval=(select max(tx.colval) from #new_values tx where tx.col=#t_all.value)
		update #t_all set colval=CAST(@keyIDout AS varchar(max)) where value=@key_column

		/****** assemble the query, replacing column names with new values if necessary ******/
		SELECT @query = 'INSERT INTO '+@tableFullName+'('+APSYS.dbo.list(t.value,',')+')'
			+' SELECT '+APSYS.dbo.list(case when t.colval is null then t.value else t.colval+' '+t.value end,',')
			+' FROM '+ @tableFullName + ' WHERE ' + @key_column + '=' + CAST(@keyID as varchar(10))
		FROM #t_all as t 

		EXEC(@query) IF @@ROWCOUNT>0 SET @keyIDout=@@IDENTITY ELSE RAISERROR('Record not created', 16, 1)
		
		COMMIT TRAN linecopy
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT=0 RETURN 
		ROLLBACK TRAN
		SELECT ERROR_MESSAGE() as ERROR_MESSAGE,@query as query
		SET @keyIDout = -1      
	END CATCH
set nocount off;
END
GO
