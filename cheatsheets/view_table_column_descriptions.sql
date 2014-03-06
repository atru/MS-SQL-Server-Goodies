USE AdventureWorks2008

SET QUOTED_IDENTIFIER OFF

DECLARE @tables table (id int identity, table_name varchar(1000), schema_name varchar(1000))
INSERT INTO @tables (table_name,schema_name)
	SELECT t0.name,s0.name
		FROM sys.tables t0
			JOIN sys.schemas s0 ON (t0.schema_id=s0.schema_id)

declare @i int = 0,@cnt int,@query varchar(max),@table_name varchar(1000),@schema_name varchar(1000)
SELECT @cnt=COUNT(*) FROM @tables
WHILE @i<@cnt BEGIN SET @i+=1
	SELECT @table_name = table_name,@schema_name=schema_name from @tables WHERE id=@i
	select @query = "
		if exists (SELECT top 1 * 
				FROM fn_listextendedproperty (default,'schema','"+@schema_name+"','table','"+@table_name+"',default,null))
			SELECT '"+@table_name+"' as table_name,* 
				FROM fn_listextendedproperty (default,'schema','"+@schema_name+"','table','"+@table_name+"',default,null);

		if exists (SELECT top 1 * 
				FROM fn_listextendedproperty (default,'schema','"+@schema_name+"','table','"+@table_name+"','column',null))
				
			SELECT '"+@table_name+"' as table_name,* 
				FROM fn_listextendedproperty (default,'schema','"+@schema_name+"','table','"+@table_name+"','column',null);
		"
	EXEC (@query)
END

SET QUOTED_IDENTIFIER ON
