# cfsqliteschema.cfc from cfsqlite version 1.0.1

Provides convenience functions for clearing and creating empty databases and also a rudimentary object model for a database row.

## DESCRIPTION

**cfsqliteschema.cfc** can be instantiated once for each SQLite database and kept in an `Application`-scope variable. The library is meant to work side-by-side with normal `cfquery`-style database access, while adding a few convenience functions to save time with SQLite-specific tasks.

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

So for example, to find the correct `cfsqltype` value for a `cfqueryparam` involving the `text` column in the `comment` table, use

	<cfqueryparam cfsqltype="#schema.comment.text.cftype#" value="...">

The table names and column names are stored specifically in the structure to ensure correct spelling of both and to remember the default order of column names.

After the first database access in an application instance, the schema is cached by cfsqlite, so instantiating `cfsqliteschema` at the start of each request does not incur a delay. (You must explicitly `Refresh()` the structure if you change your database structure outside of your application.)

## EXAMPLE

	<!--- Instantiation --->
	<cfset DSN="...DATASOURCE NAME...">
    <cfset schema=CreateObject("component", "MYAPP.lib.cfsqliteschema").Init(DSN)>

	<!--- Data definition --->
	<cfset schema.DeleteAllObjects()>
	<cfset schema.CreateTable(
		"comment",
		"id PK",
		"author_name TEXT",
		"date TEXT",
		"text TEXT"
	)>
	<cfset schema.Refresh()>
	
	<!--- Record loading and saving --->
	<cfset rec=schema.Record("comment")>
	<cfset rec.author_name="me")>
	<cfset rec.date=Now()>
	<cfset rec.text="some text")>
	<cfset rec.Save()>
	<cfset id=rec.id>
	<cfset rec=schema.Record("comment").Load(id)>
	<cfset rec.text="other text")>
	<cfset rec.Save()>
	
	<!--- Compact the database --->
	<cfset schema.Compact()>

## REQUIREMENTS

ColdFusion 8

## SEE ALSO

[SQLite](http://sqlite.org/) web site; [syntax documentation](http://sqlite.org/lang.html).

## PROPERTIES

<dl><dt><b>_dsn</b></dt>
<dd>Data Source name.</dd>
<dt><b>_tableNames</b></dt>
<dd>List of table names with correct capitalization from the database.</dd></dl>

## FUNCTIONS

### Compact

`Compact()`

Compact the database.

access: `public`<br>
returns: `cfsqliteschema`

<dl></dl>

### CreateIndex

`CreateIndex(IndexName, Table, ColumnList, RequireUnique)`

Create new index in the database.

access: `public`<br>
returns: `cfsqliteschema`

<dl><dt><code>string</code> <b><code>IndexName</code></b></dt><dd>Name of the new index</dd>

<dt><code>string</code> <b><code>Table</code></b></dt><dd>Table containing the target column</dd>

<dt><code>string</code> <b><code>ColumnList</code></b></dt><dd>List of columns to be used as the index key following the format of the <a href="http://www.sqlite.org/syntaxdiagrams.html#indexed-column">indexed-column</a> part of an SQLite <code>CREATE INDEX</code> statement.</dd>

<dt><i>optional</i> <code>boolean</code> <b><code>RequireUnique</code></b> <span style="color: Gray;">(default "false")</span></dt><dd>Include <code>UNIQUE</code> constraing on the index.</dd></dl>

### CreateTable

`CreateTable(Table, Column1, Column2, Column3)`

Create new table in the database. The first argument is the name of the table, and all subsequent arguments are column specifications as you would give them in an SQLite <code>CREATE TABLE</code> statement. &quot;<code>PK</code>&quot; in a column specification is a shortcut for &quot;<code>INTEGER PRIMARY KEY AUTOINCREMENT</code>&quot;. See <a href="http://http://www.sqlite.org/lang_createtable.html">SQLite documentation for CREATE TABLE</a>. (Don't forget to call <code>Refresh()</code> after your last <code>CreateTable()</code>.)

access: `public`<br>
returns: `cfsqliteschema`

<dl><dt><code>string</code> <b><code>Table</code></b></dt><dd></dd>

<dt><code>string</code> <b><code>Column1</code></b></dt><dd></dd>

<dt><i>optional</i> <code>string</code> <b><code>Column2</code></b></dt><dd></dd>

<dt><i>optional</i> <code>string</code> <b><code>Column3</code></b></dt><dd>... and so on</dd></dl>

### DropAllObjects

`DropAllObjects()`

Drop all Tables, Views, Indices, and Triggers; compact the database; refresh schema. Use this method to reset the database to an empty state.

access: `public`<br>
returns: `cfsqliteschema`

<dl></dl>

### Init

`Init(dsn, GlobalContainer)`

Constructor.

access: `public`<br>
returns: `cfsqliteschema`

<dl><dt><code>string</code> <b><code>dsn</code></b></dt><dd>The datasource name to scan</dd>

<dt><i>optional</i> <b><code>GlobalContainer</code></b> <span style="color: Gray;">(default "#Application#")</span></dt><dd>(<b>struct</b>) Where to store application-level global cache of database schemas.</dd></dl>

### Record

`Record(Table, Query)`

<p>Get a <code>cfsqliterecord</code> instance representing an empty database row.</p>

access: `public`<br>
returns: `struct`

<dl><dt><code>string</code> <b><code>Table</code></b></dt><dd>Name of the table to create an empty record for.</dd>

<dt><i>optional</i> <code>query</code> <b><code>Query</code></b></dt><dd>A <code>query</code> object whose current record will be loaded into the <code>cfsqliterecord</code> object. Default is a blank record.</dd></dl>

### Refresh

`Refresh()`

Refresh the schema from the live database.

access: `public`<br>
returns: `cfsqliteschema`

<dl></dl>
