# cfsqliterecord.cfc from cfsqlite version 1.0.1

Provides a simple object to represent an SQLite database row.

## DESCRIPTION

**cfsqliterecord.cfc** can be instantiated from the `cfsqliteschema.Record()` method, or you can also create an instance directly by passing in a `cfsqliteschema` instance and a table name to the `cfsqliterecord.Init()` method.

The `cfsqliterecord` object contains a field for each column in the table it was instantiated from. Upon `Save()`, only fields that were changes since the last `Load()` are written to the database.

To insert a new row in a table with an autonumber primary key column, leave the `id` column empty, and it will be filled in after `Save()` returns.

## EXAMPLE

(See example in `cfsqliteschema.cfc`.)

## REQUIREMENTS

ColdFusion 8

## SEE ALSO

[SQLite](http://sqlite.org/) web site; [syntax documentation](http://sqlite.org/lang.html).

## PROPERTIES

<dl><dt><i>string</i> <b>_dsn</b></dt>
<dd>Data Source name.</dd>
<dt><i>string</i> <b>_table</b></dt>
<dd>Table name.</dd></dl>

## FUNCTIONS

### Init

`Init(Schema, Table, Query)`

Constructor.

access: `public`<br>
returns: `cfsqliterecord`

<dl><dt><code>cfsqliteschema</code> <b><code>Schema</code></b></dt><dd>A <code>cfsqliteschema</code> instance</dd>

<dt><code>string</code> <b><code>Table</code></b></dt><dd>Table name</dd>

<dt><i>optional</i> <code>query</code> <b><code>Query</code></b></dt><dd>A <code>query</code> object whose current record will be loaded into the <code>cfsqliterecord</code> object. Default is a blank record.</dd></dl>

### Load

`Load(ID, IDColumnName)`

Load a record with the given id.

access: `public`<br>
returns: `cfsqliterecord`

<dl><dt><b><code>ID</code></b></dt><dd>Value in 'id' column</dd>

<dt><i>optional</i> <code>string</code> <b><code>IDColumnName</code></b> <span style="color: Gray;">(default "id")</span></dt><dd>Name of primary key column</dd></dl>

### Save

`Save(IDColumnName)`

Save a record.

access: `public`<br>
returns: `cfsqliterecord`

<dl><dt><i>optional</i> <code>string</code> <b><code>IDColumnName</code></b> <span style="color: Gray;">(default "id")</span></dt><dd>Name of primary key column</dd></dl>
