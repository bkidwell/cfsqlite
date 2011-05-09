<cfcomponent output="false" hint="<br /><p><b>cfsqliteschema.cfc</b> version
0.20 &ndash; Reads and modifies SQLite schema from a data source and provides
simple record loading and saving objects.</p>
<p><a href=""https://github.com/bkidwell/cfsqlite"">Home page on github</a><p>
"><!---

# cfsqliteschema.cfc

Reads and modifies SQLite schema from a data source and provides simple record
loading and saving objects.

## SYNOPSIS

    Instantiate:
	<cfset schema=CreateObject("component", "MYAPP.lib.cfsqliteschema").Init(DSN)>

	Refresh if schema changed by external process
	<cfset schema.Refresh()>

	Drop all Tables, Views, Indices, and Triggers (automatic compact afterwards):
	<cfset schema.DropAllObjects()>

	Create Table:
	<cfset schema.CreateTable("TABLE_NAME", "COLUMN_1, (SQLite column spec 1)",
		"COLUMN_2, (SQLite column spec 2)", ...)>

	Create empty record as a struct struct:
	<cfset rec=schema.Record("TABLE_NAME")>
	
	Load a record with a given value in 'id' column:
	<cfset rec=schema.Record("TABLE_NAME").Load("ID")>
	
	Load a record from the current record in a query object:
	<cfset rec=schema.Record("TABLE_NAME").Load(QUERY_NAME)>
	
	Edit record:
	<cfset rec.col1="a value">
	<cfset rec.col2="another value">
	<cfset rec.Save()>
	
	Compact the database:
	<cfset schema.Compact()>

## DESCRIPTION

**cfsqliteschema** is a ColdFusion library that provides shortcuts for accessing
records in [SQLite](http://sqlite.org/) databases as `structs` and for creating
tables in a new SQLite database. It is designed to work side-by-side with normal
`cfquery`-style database access.

**cfsqliteschema** should only be used in a development or demonstration
environment, unless you're sure you know what you're doing. SQLite does not
handle multiple concurrent users well. SQLite's strength is in integrating the
database engine into a library running in the application's process, thereby
allowing developers to get up and running with a project quickly without setting
up a separate enterprise database engine. It's great for distributing
sample/howto code.

## INSTALLATION

1. Copy `lib/cfsqliteschema.cfc` into your application's `ext` or `lib` folder, or
wherever you store external libraries.

(The other files you see in the distribution of this library are for testing and
preparing the documentation.)

## EXAMPLE

	[comment] Instantiation [/comment]
	<cfset DSN="...DATASOURCE NAME...">
    <cfset schema=CreateObject("component", "MYAPP.lib.cfsqliteschema").Init(DSN)>

	[comment] Data definition [/comment]
	<cfset schema.DeleteAllObjects()>
	<cfset schema.CreateTable(
		"comment",
		"id, PK",
		"author_name, TEXT",
		"date, TEXT",
		"text, TEXT"
	)>
	
	[comment] Record loading and saving [/comment]
	<cfset rec=schema.Record("comment")>
	<cfset rec.author_name="me")>
	<cfset rec.date=Now()>
	<cfset rec.text="some text")>
	<cfset rec.Save()>
	<cfset id=rec.id>
	<cfset rec=schema.Record("comment").Load(id)>
	<cfset rec.text="other text")>
	<cfset rec.Save()>
	
	[comment] Compact the database [/compact]
	<cfset schema.Compact()>

## NOTES

**cfsqliteschema** is meant to be used in combination with **cfsqlite** which
handles setting up data sources in the ColdFusion global configuration, but
**cfsqliteschema** is an independent library.

When creating a table, a column spec is given as an optional data type name
followed by optional SQLite data definition keywords such as "`PRIMARY KEY`".
"`PK`" is a shortcut for "`INTEGER PRIMARY KEY AUTOINCREMENT`".

## REQUIREMENTS

ColdFusion 8

## HISTORY

Version 0.20 -- first release of **cfsqlite** library collection including
**cfsqliteschema**.

## HOMEPAGE

[cfsqlite web site](https://github.com/bkidwell/cfsqlite)

## SEE ALSO

doc/api-cfsqliteschema.html -- **cfsqliteschema** API documentation

[SQLite](http://sqlite.org/) web site; [syntax
documentation](http://sqlite.org/lang.html).

## AUTHOR

Brendan Kidwell <[brendan@glump.net](mailto:brendan@glump.net)\>.

Please drop me a line if you find **cfsqlite** useful (or if you find a
problem.)

## COPYRIGHT

Copyright © 2011 Brendan Kidwell

Permission to use, copy, modify, and/or distribute this software for any purpose
with or without fee is hereby granted, provided that the above copyright notice
and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS
OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER
TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF
THIS SOFTWARE.

--->

<cfproperty name="_dsn" hint="Datasource name">

<!--- reserved words to filter out when looking for SQL data type in DDL string --->
<cfset KEYWORDS="ABORT,ACTION,ADD,AFTER,ALL,ALTER,ANALYZE,AND,AS,ASC," &
"ATTACH,AUTOINCREMENT,BEFORE,BEGIN,BETWEEN,BY,CASCADE,CASE,CAST,CHECK," &
"COLLATE,COLUMN,COMMIT,CONFLICT,CONSTRAINT,CREATE,CROSS,CURRENT_DATE," &
"CURRENT_TIME,CURRENT_TIMESTAMP,DATABASE,DEFAULT,DEFERRABLE,DEFERRED," &
"DELETE,DESC,DETACH,DISTINCT,DROP,EACH,ELSE,END,ESCAPE,EXCEPT,EXCLUSIVE," &
"EXISTS,EXPLAIN,FAIL,FOR,FOREIGN,FROM,FULL,GLOB,GROUP,HAVING,IF,IGNORE," &
"IMMEDIATE,IN,INDEX,INDEXED,INITIALLY,INNER,INSERT,INSTEAD,INTERSECT,INTO," &
"IS,ISNULL,JOIN,KEY,LEFT,LIKE,LIMIT,MATCH,NATURAL,NO,NOT,NOTNULL,NULL,OF," &
"OFFSET,ON,OR,ORDER,OUTER,PLAN,PRAGMA,PRIMARY,QUERY,RAISE,REFERENCES," &
"REGEXP,REINDEX,RELEASE,RENAME,REPLACE,RESTRICT,RIGHT,ROLLBACK,ROW," &
"SAVEPOINT,SELECT,SET,TABLE,TEMP,TEMPORARY,THEN,TO,TRANSACTION,TRIGGER," &
"UNION,UNIQUE,UPDATE,USING,VACUUM,VALUES,VIEW,VIRTUAL,WHEN,WHERE">

<cffunction name="Init"
	access="public" output="false" returnType="cfsqliteschema"
	hint="Constructor">
		
	<cfargument name="dsn" type="string" required="true"
		hint="The datasource name to scan">
	<cfset var tablesQ="">
	<cfset var table="">
	<cfset var tableNamesA=ArrayNew(1)>

	<cfset this._dsn=Arguments.dsn>
	<cfdbinfo datasource="#Request.DSN#" name="tablesQ" type="tables">

	<cfloop query="tablesQ">
		<cfif Left(tablesQ.table_name, 7) NEQ "SQLITE_">
			<cfset table=ScanTable(tablesQ.table_name)>
			<cfset this[tablesQ.table_name]=table>
			<cfset ArrayAppend(tableNamesA, table._name)>
		</cfif>
	</cfloop>

	<cfset this._tableNames=ArrayToList(tableNamesA)>
	<cfreturn this>	
</cffunction>

<cffunction name="ScanTable"
	access="private" output="false" returnType="struct"
	hint="Scans a table and returns a struct of columns">

	<cfargument name="tablename" type="string" required="true"
		hint="Table name to scan">
	<cfset var sqlQ="">
	<cfset var sql="">
	<cfset var table=StructNew()>
	<cfset var columnSqlA="">
	<cfset var i="">
	<cfset var column="">
	<cfset var colsSql="">
	<cfset var columnNamesA=ArrayNew(1)>
	
	<cfquery datasource="#this._dsn#" name="sqlQ">
		SELECT sql, name FROM sqlite_master
		WHERE name LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#Arguments.tablename#">
	</cfquery>
	<cfset table._name=sqlQ.name>
	<cfset table._sql=REReplace(sqlQ.sql, "/\*.*?\*/", "", "all")>
	<cfset table._sql=REReplace(table._sql, "--.*?\n", Chr(10), "all")>
	
	<!--- get SQL code between outer set of parentheses --->
	<cfset colsSql=ListDeleteAt("#table._sql#;", 1, "(")>
	<cfset colsSql=ListDeleteAt(  colsSql, ListLen(colsSql, ")"), ")"  )>
	
	<cfset columnSqlA=colsSql.split(",")>
	<cfloop index="i" array="#columnSqlA#">
		<cfset column=ScanColumn(i)>
		<cfset table[column.name]=column>
		<cfset ArrayAppend(columnNamesA, column.name)>
	</cfloop>

	<cfset table._columnNames=ArrayToList(columnNamesA)>
	<cfreturn table>
</cffunction>

<cffunction name="ScanColumn"
	access="private" output="false" returnType="struct"
	hint="Scans an SQL snippet representing one column from a CREATE TABLE SQL statement">
	
	<cfargument name="sql" type="string" required="true"
		hint="SQL snippet for columnn definition">
	<cfset var name="">
	<cfset var delim="">
	<cfset var type="">
	<cfset var column=StructNew()>
	<cfset var className="">

	<cfdump var="#Arguments#">
	<cfset Arguments.sql=Trim(Arguments.sql)>
	<cfif Left(Arguments.sql, 1) EQ """">
		<cfset delim="""">
	<cfelseif Left(Arguments.sql, 1) EQ "'">
		<cfset delim="'">
	<cfelse>
		<cfset delim=" ">
	</cfif>
	<cfset column.name=ListFirst(Arguments.sql, delim)>
	<cfset Arguments.sql=ListDeleteAt(Arguments.sql, 1, delim)>
	<cfif Left(Arguments.sql, 1) EQ delim>
		<cfset Arguments.sql=Mid(Arguments.sql, 2, Len(Arguments.sql) - 1)>
	</cfif>
	
	<cfset column.type=ListFirst(Arguments.sql, " ")>
	<cfif ListFind(KEYWORDS, type) GT 0>
		<!--- first word after column name isn't type name --->
		<cfset column.type="">
	</cfif>
	<cfset className=GetStorageClass(column.type)>
	<cfset column.class=ListFirst(className)>
	<cfset column.cftype=ListLast(className)>
	
	<cfreturn column>
</cffunction>

<cffunction name="GetStorageClass"
	access="private" output="false" returnType="string"
	hint="Returns an SQLite storage class name for a given type name">
	
	<cfargument name="type" type="string" required="true"
		hint="Type name">
	
	<!--- http://www.sqlite.org/datatype3.html --->
	
	<!--- If the declared type contains the string "INT" then it is
	assigned INTEGER affinity. --->
	<cfif FindNoCase(Arguments.type, "INT") GT 0><cfreturn "INTEGER,CF_SQL_INTEGER"></cfif>

	<!--- If the declared type of the column contains any of the strings
	"CHAR", "CLOB", or "TEXT" then that column has TEXT affinity. --->
	<cfif FindNoCase(Arguments.type, "CHAR") GT 0><cfreturn "TEXT,CF_SQL_VARCHAR"></cfif>
	<cfif FindNoCase(Arguments.type, "CLOB") GT 0><cfreturn "TEXT,CF_SQL_VARCHAR"></cfif>
	<cfif FindNoCase(Arguments.type, "TEXT") GT 0><cfreturn "TEXT,CF_SQL_VARCHAR"></cfif>
	
	<!--- If the declared type for a column contains the string "BLOB" or
	if no type is specified then the column has affinity NONE. --->
	<cfif FindNoCase(Arguments.type, "BLOB") GT 0><cfreturn "NONE,CF_SQL_BLOB"></cfif>
	<cfif Arguments.type EQ ""><cfreturn "NONE,CF_SQL_VARCHAR"></cfif>
	
	<!--- If the declared type for a column contains any of the strings
	"REAL", "FLOA", or "DOUB" then the column has REAL affinity. --->
	<cfif FindNoCase(Arguments.type, "REAL") GT 0><cfreturn "REAL,CF_SQL_REAL"></cfif>
	<cfif FindNoCase(Arguments.type, "FLOA") GT 0><cfreturn "REAL,CF_SQL_REAL"></cfif>
	<cfif FindNoCase(Arguments.type, "DOUB") GT 0><cfreturn "REAL,CF_SQL_REAL"></cfif>		

	<!--- Otherwise, the affinity is NUMERIC. --->
	<cfreturn "NUMERIC,CF_SQL_NUMERIC">
	
</cffunction>

</cfcomponent>