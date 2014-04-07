copyrow
=======

These scripts allow row copying functionality in MS SQL.

For example
```sql
EXEC SYSDB.dbo._CopyRow 
    @tableFullName='AdventureWorks2008.SalesLT.Product'
    ,@keyID=999
    ,@todo="col1=new value;col2=newer value"
    ,@keyIDout=@newKeyID OUT
```
would copy a row with key `@keyID=999`, change the values according to `@todo="col1=new value;col2=newer value` and return the inserted key as an out parameter `@keyIDout=@newKeyID OUT`.

Installation
============

See this [blog post](http://atru.github.io/en/2014/04/03/copy-row.html) for more info.

Compatibility
=============
Tested to work in MS SQL 2008 R2 and MS SQL 2012.
