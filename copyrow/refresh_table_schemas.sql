USE [SYSDB]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
/**@file Refresh structure data (table schemas)*/
/**@author Alex Truman*/
/**@code
EXEC SYSDB..[_refresh_table_schemas] @dbname='Adventureworks2008', @objName='Adventureworks2008.SalesLT.Product'
@endcode*/
ALTER PROCEDURE [dbo].[_refresh_table_schemas]
	@dbname		varchar(100)=NULL		/**@param DB name*/
	,@objname	varchar(255)=NULL		/**@param Table name*/
AS
BEGIN
DECLARE @obj_id bigint
DECLARE @sql	varchar(max)
declare @i int, @cnt int
	
	if OBJECT_ID('SYSDB.._table_schemas') IS NULL
		CREATE TABLE SYSDB.._table_schemas(
			[db] [varchar](32) NOT NULL,
			[object_id] [int] NOT NULL,
			[name] [sysname] NULL,
			[type] [sysname] NOT NULL,
			[column_id] [int] NOT NULL,
			[is_nullable] [bit] NULL,
			[is_identity] [bit] NOT NULL,
			[length] [varchar](10) NULL,
			[precision] [varchar](10) NULL,
			[scale] [varchar](10) NULL,
			[StrLen] [smallint] NOT NULL,
			[LITERAL_PREFIX] [varchar](32) NULL,
			[LITERAL_SUFFIX] [varchar](32) NULL,
			[primary_key] [varchar](1) NULL
		)
	if (ISNULL(@dbname,'')='') set @objname=NULL
	if ISNULL(@objname,'')<>'' set @obj_id=OBJECT_ID(@objname)
	DECLARE @tmp_db TABLE (num int identity, dbname varchar(64))

	INSERT INTO @tmp_db(dbname) SELECT [name] FROM master..[sysdatabases] WHERE[name]=ISNULL(@dbname,[name])

	if (ISNULL(@dbname,'')='') truncate table SYSDB.._table_schemas
	else delete from SYSDB.._table_schemas where db=@dbname and object_id=ISNULL(@obj_id,object_id)
	
	select @i=0, @cnt=isnull((select MAX(num) from @tmp_db),0),@dbname=null
	while @i<@cnt begin set @i=@i+1 select @dbname=dbname from @tmp_db where num=@i

		set @sql="INSERT INTO SYSDB.._table_schemas SELECT '" +@dbname+"' db, C.object_id, C.name, Tp.name AS type, C.column_id, C.is_nullable, C.is_identity,
				(CASE when ST.CREATE_PARAMS is null then '' WHEN CHARINDEX(',',ST.CREATE_PARAMS)>0 then CAST(Tp.precision AS varchar(10)) ELSE CAST(C.max_length AS varchar(10)) END) AS length, 
				(CASE WHEN CHARINDEX(',',ST.CREATE_PARAMS)>0 then CAST(C.scale AS varchar(10)) ELSE '' END) AS scale,
				(CASE WHEN CHARINDEX(',',ST.CREATE_PARAMS)>0 then CAST(C.precision AS varchar(10)) ELSE '' END) AS precision,
				(CASE WHEN C.precision > 0 THEN C.precision WHEN C.precision = 0 AND C.max_length > 0 THEN C.max_length ELSE Tp.max_length END) AS StrLen,
				ST.LITERAL_PREFIX COLLATE Latin1_General_CI_AS AS LITERAL_PREFIX, ST.LITERAL_SUFFIX COLLATE Latin1_General_CI_AS AS LITERAL_SUFFIX,
				(CASE WHEN t2.is_primary_key=1 THEN 'Y' END) AS primary_key
			FROM "+@dbname+".sys.columns AS C JOIN "+@dbname+".sys.types AS Tp ON(C.system_type_id = Tp.system_type_id) 
					JOIN SYSDB.._datatype_info AS ST ON(Tp.name COLLATE Cyrillic_General_CI_AS = ST.TYPE_NAME)
					left join "+@dbname+".sys.index_columns t1 on(t1.column_id = C.column_id and t1.object_id = C.object_id)
					left JOIN "+@dbname+".sys.indexes t2 on(t1.object_id = t2.object_id AND t1.index_id = t2.index_id)"
			+(case when ISNULL(@obj_id,0)>0 then " WHERE C.object_id="+CAST(@obj_id as varchar) else "" end)
		exec(@sql)
	end
END
GO

GO
-- TEST

--EXEC SYSDB..[_refresh_table_schemas]
--EXEC SYSDB..[_refresh_table_schemas] @dbname='Adventureworks2008', @objName='Adventureworks2008.SalesLT.Product'

--SELECT * FROM SYSDB.._table_schemas where db='Adventureworks2008'
