<cfcomponent output="false" hint="<br /><p><b>cfsqliteschema.cfc</b>
from cfsqlite version 1.0<p>
<p>Reads and modifies SQLite schema from a data source and provides simple
record loading and saving objects.</p>
<p><a href=""https://github.com/bkidwell/cfsqlite"">Home page on github</a><p>
"><!---

# cfsqliteschema.cfc from cfsqlite version 1.0

Provides convenience functions for clearing and creating empty databases and
also a rudimentary object model for a database row.

## DESCRIPTION

**cfsqliteschema.cfc** can be instantiated once for each SQLite database and
kept in an `Application`-scope variable. The library is meant to work
side-by-side with normal `cfquery`-style database access, while adding a few
convenience functions to save time with SQLite-specific tasks.

A `cfsqliteschema` instance contains a map of your database schema:

	_dsn # data source name
	_tableNames      # list of table names
	TABLE1 = {
		_name        # name of this table
		_columnNames # list of column names
		_sql         # SQL statement that created the table
		COLUMN1 = {
			name     # name of this column
			type     # data type from SQL CREATE TABLE statement
			class    # SQLite storage class name
			cftype   # for use in <cfqueryparam cfsqltype="...">
		}
		COLUMN2 = { ... }
		...
	}
	TABLE2 = { ... }
	...

So for example, to find the correct `cfsqltype` value for a `cfqueryparam`
involving the `text` column in the `comment` table, use

	<cfqueryparam cfsqltype="#schema.comment.text.cftype#" value="...">

The table names and column names are stored specifically in the structure to
ensure correct spelling of both and to remember the default order of column
names.

After the first database access in an application instance, the schema is cached
by cfsqlite, so instantiating `cfsqliteschema` at the start of each request does
not incur a delay. (You must explicitly `Refresh()` the structure if you change
your database structure outside of your application.)

## EXAMPLE

	[comment] Instantiation [/comment]
	<cfset DSN="...DATASOURCE NAME...">
    <cfset schema=CreateObject("component", "MYAPP.lib.cfsqliteschema").Init(DSN)>

	[comment] Data definition [/comment]
	<cfset schema.DeleteAllObjects()>
	<cfset schema.CreateTable(
		"comment",
		"id PK",
		"author_name TEXT",
		"date TEXT",
		"text TEXT"
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
	
	[comment] Compact the database [/comment]
	<cfset schema.Compact()>

## REQUIREMENTS

ColdFusion 8

## SEE ALSO

[SQLite](http://sqlite.org/) web site; [syntax
documentation](http://sqlite.org/lang.html).

---><!---

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

<cfproperty name="_dsn" hint="Data Source name.">

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
	hint="Constructor.">
		
	<cfargument name="dsn" type="string" required="true"
		hint="The datasource name to scan">
	<cfargument name="GlobalContainer" default="##Application##"
		hint="(<b>struct</b>) Where to store application-level global cache of
		database schemas.">

	<cfif NOT IsStruct(Arguments.GlobalContainer)>
		<cfset Arguments.GlobalContainer=Application>
	</cfif>

	<cfif NOT IsDefined("Arguments.GlobalContainer.cfsqliteschemas")>
		<cflock timeout="90" scope="Application" type="exclusive">
			<cfset Arguments.GlobalContainer.cfsqliteschemas=StructNew()>
		</cflock>
	</cfif>
	
	<!--- append "?resetcfsqlite=1" to URL to reset while debugging --->
	<cfif
		StructKeyExists(Arguments.GlobalContainer.cfsqliteschemas, Arguments.dsn) AND
		NOT IsDefined("URL.resetcfsqlite")
	>
		<!--- return cached schema from Application scope --->
		<cfreturn Arguments.GlobalContainer.cfsqliteschemas[Arguments.dsn]>
	</cfif>
	
	<cflock timeout="90" scope="Application" type="exclusive">
		<cfset this._dsn=Arguments.dsn>
		<cfset Refresh()>
		<cfset Arguments.GlobalContainer.cfsqliteschemas[Arguments.dsn]=this>
	</cflock>

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

<cffunction name="Refresh"
	access="public" output="false" returnType="cfsqliteschema"
	hint="Refresh the schema from the live database.">

	<cfset var tablesQ="">
	<cfset var table="">
	<cfset var tableNamesA=ArrayNew(1)>

	<cfdbinfo datasource="#this._dsn#" name="tablesQ" type="tables">

	<cfloop query="tablesQ">
		<cfif Left(tablesQ.table_name, 7) NEQ "SQLITE_" AND tablesQ.table_type EQ "TABLE">
			<cfset table=ScanTable(tablesQ.table_name)>
			<cfset this[tablesQ.table_name]=table>
			<cfset ArrayAppend(tableNamesA, table._name)>
		</cfif>
	</cfloop>

	<cfset this._tableNames=ArrayToList(tableNamesA)>
	<cfreturn this>
</cffunction>

<cffunction name="DropAllObjects"
	access="public" output="false" returnType="cfsqliteschema"
	hint="Drop all Tables, Views, Indices, and Triggers; compact the database;
	refresh schema. Use this method to reset the database to an empty state.">

	<cfquery name="tables" datasource="#this._dsn#">
		SELECT type, name FROM sqlite_master WHERE type IN ('table', 'index', 'view', 'trigger')
	</cfquery>
	<cfloop query="tables">
		<cfif Left(tables.name, 7) NEQ "sqlite_"><cfquery datasource="#this._dsn#">
			DROP #tables.type# IF EXISTS "#tables.name#"
		</cfquery></cfif>
	</cfloop>
	<cfset Compact()>
	<cfset Refresh()>
	<cfreturn this>
</cffunction>

<cffunction name="CreateTable"
	access="public" output="false" returnType="cfsqliteschema"
	hint="Create new table in the database. The first argument is the name of
	the table, and all subsequent arguments are column specifications as you
	would give them in an SQLite <code>CREATE TABLE</code> statement.
	&quot;<code>PK</code>&quot; in a column specification is a shortcut for
	&quot;<code>INTEGER PRIMARY KEY AUTOINCREMENT</code>&quot;. See
	<a href=""http://http://www.sqlite.org/lang_createtable.html"">SQLite
	documentation for CREATE TABLE</a>. (Don't forget to call
	<code>Refresh()</code> after your last <code>CreateTable()</code>.)">

	<cfargument name="Table" type="string" required="true">
	<cfargument name="Column1" type="string" required="true">
	<cfargument name="Column2" type="string">
	<cfargument name="Column3" type="string" hint="... and so on">
	<cfset var cols="">
	<cfset var column="">
	<cfset var i="">
	
	<cfset cols=ArrayNew(1)>
	<cfloop index="i" from="2" to="#ArrayLen(Arguments)#">
		<cfset column=Arguments[i]>
		<cfif IsDefined("column") AND Len(column) GT 0>
			<cfif Right(column, 3) EQ " PK">
				<cfset column=Left(column, Len(column) - 2) & "INTEGER PRIMARY KEY AUTOINCREMENT">
			</cfif>
			<cfset ArrayAppend(cols, column)>
		</cfif>
	</cfloop>
	<cfquery datasource="#this._dsn#">
		CREATE TABLE "#Arguments.Table#" (
			#ArrayToList(cols, ", ")#
		)
	</cfquery>
	
	<cfreturn this>
</cffunction>

<cffunction name="CreateIndex"
	access="public" output="false" returnType="cfsqliteschema"
	hint="Create new index in the database.">
	
	<cfargument name="IndexName" type="string" required="true"
		hint="Name of the new index">
	<cfargument name="Table" type="string" required="true"
		hint="Table containing the target column">
	<cfargument name="ColumnList" type="string" required="true"
		hint="List of columns to be used as the index key following the format
		of the
		<a href=""http://www.sqlite.org/syntaxdiagrams.html##indexed-column"">indexed-column</a>
		part of an SQLite <code>CREATE INDEX</code> statement.">
	<cfargument name="RequireUnique" type="boolean" default="false"
		hint="Include <code>UNIQUE</code> constraing on the index.">

	<cfquery datasource="#this._dsn#">
		CREATE <cfif Arguments.RequireUnique>UNIQUE</cfif> INDEX
		"#Arguments.IndexName#" ON "#Arguments.Table#" (#Arguments.ColumnList#)
	</cfquery>
	
	<cfreturn this>
</cffunction>

<cffunction name="Compact"
	access="public" output="false" returnType="cfsqliteschema"
	hint="Compact the database.">
	
	<cfquery datasource="#this._dsn#">VACUUM</cfquery>
	<cfreturn this>
</cffunction>

<cffunction name="Record"
	access="public" output="false" returnType="struct"
	hint="<p>Get a <code>struct</code> representing an empty database row.</p>
	<p>The returned <code>struct</code> has two extra methods added to it:
	<code>Load(id)</code> loads the record from the database with the given
	<code>id</code> value; <code>Save()</code> saves changes to the database.
	The <code>Save()</code> method inserts a new row or updates an existing
	row.</p>
	<p>For this method to work, the table's primary key must be called
	<code>id</code>.</p>">

	<cfargument name="Table" type="string" required="true"
		hint="Name of the table to create an empty record for.">
	<cfargument name="Query" type="query"
		hint="A <code>query</code> object whose current record will be loaded
		into the <code>cfsqliterecord</code> object. Default is a blank
		record.">

	<cfif IsDefined("Arguments.Query")>
		<cfreturn CreateObject("component", "cfsqliterecord").Init(this, Arguments.Table, Arguments.Query)>
	<cfelse>
		<cfreturn CreateObject("component", "cfsqliterecord").Init(this, Arguments.Table)>
	</cfif>
</cffunction>

</cfcomponent>
