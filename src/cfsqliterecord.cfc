<cfcomponent output="false" hint="<br /><p><b>cfsqliterecord.cfc</b> from
cfsqlite version 1.0</p>
<p>Provides a simple object to represent an SQLite database row.</p>
<p><a href=""https://github.com/bkidwell/cfsqlite"">Home page on github</a><p>
"><!---

# cfsqliterecord.cfc from cfsqlite version 1.0

Provides a simple object to represent an SQLite database row.

## DESCRIPTION

**cfsqliterecord.cfc** can be instantiated from the `cfsqliteschema.Record()`
method, or you can also create an instance directly by passing in a
`cfsqliteschema` instance and a table name to the `cfsqliterecord.Init()`
method.

The `cfsqliterecord` object contains a field for each column in the table it
was instantiated from. Upon `Save()`, only fields that were changes since the
last `Load()` are written to the database.

To insert a new row in a table with an autonumber primary key column, leave
the `id` column empty, and it will be filled in after `Save()` returns.

## EXAMPLE

(See example in `cfsqliteschema.cfc`.)

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

<cfproperty name="_dsn" type="string" hint="Data Source name.">
<cfproperty name="_table" type="string" hint="Table name.">
<cfset schema=""><!--- The schema for the chosen DSN --->
<cfset oldValues=StructNew()><!--- Struct of old values for each column --->

<cffunction name="Init"
	access="public" output="false" returnType="cfsqliterecord"
	hint="Constructor.">

	<cfargument name="Schema" type="cfsqliteschema" required="true"
		hint="A <code>cfsqliteschema</code> instance">
	<cfargument name="Table" type="string" required="true"
		hint="Table name">
	<cfargument name="Query" type="query"
		hint="A <code>query</code> object whose current record will be loaded
		into the <code>cfsqliterecord</code> object. Default is a blank
		record.">
	<cfset var i="">
	<cfset var col="">
	<cfset var v="">

	<cfset Variables.schema=Arguments.Schema>
	<cfset this._dsn=schema._dsn>
	<cfset this._table=schema[Arguments.table]._name>
	<cfloop index="i" list="#schema[Arguments.Table]._columnNames#">
		<cfif IsDefined("Arguments.Query")>
			<cfset v=Arguments.Query[i][Arguments.Query.CurrentRow]>
		</cfif>
		<cfset oldValues[i]="">
		<cfset this[i]="">
	</cfloop>

	<cfreturn this>
</cffunction>

<cffunction name="Load"
	access="public" output="false" returnType="cfsqliterecord"
	hint="Load a record with the given id.">
	
	<cfargument name="ID" required="true"
		hint="Value in 'id' column">
	<cfargument name="IDColumnName" type="string" default="id"
		hint="Name of primary key column">
	<cfset var q="">
	<cfset var i="">
	
	<cfquery datasource="#this._dsn#" name="q">
		SELECT * FROM "#this._table#"
		WHERE "#Arguments.IDColumnName#"=#Param(
			Arguments.ID,
			schema[this._table][Arguments.IDColumnName].class
		)#
	</cfquery>
	<cfloop index="i" list="#schema[this._table]._columnNames#">
		<cfset this[i]=q[i][1]>
		<cfset oldValues[i]=this[i]>
	</cfloop>

	<cfreturn this>
</cffunction>

<cffunction name="Save"
	access="public" output="false" returnType="cfsqliterecord"
	hint="Save a record.">

	<cfargument name="IDColumnName" type="string" default="id"
		hint="Name of primary key column">
	
	<cfif Len(oldValues[Arguments.IDColumnName]) EQ 0>
		<cfset DbInsert(Arguments.IDColumnName)>
	<cfelse>
		<cfset DbUpdate(Arguments.IDColumnName)>
	</cfif>
	<cfset Load(this[Arguments.IDColumnName], Arguments.IDColumnName)>

	<cfreturn this>
</cffunction>

<cffunction name="DbInsert"
	access="private" output="false" returnType="void"
	hint="Insert a record">

	<cfargument name="IDColumnName" type="string" default="id"
		hint="Name of primary key column">
	
	<cfset var i="">
	<cfset var changes="">
	<cfset var comma="">
	<cfset var q="">

	<cfloop index="i" list="#schema[this._table]._columnNames#">
		<cfif Compare(this[i], oldValues[i]) NEQ 0>
			<cfset changes=ListAppend(changes, i)>
		</cfif>
	</cfloop>

	<cfquery datasource="#this._dsn#">
		INSERT INTO "#this._table#" (
		<cfset comma=""><cfloop index="i" list="#changes#">
			#comma# "#i#"<cfset comma=",">
		</cfloop>
		) VALUES (
		<cfset comma=""><cfloop index="i" list="#changes#">
			#comma# #Param(this[i], schema[this._table][i].class)#<cfset comma=",">
		</cfloop>
		)
	</cfquery>
	<cfif schema[this._table][Arguments.IDColumnName].type EQ "INTEGER">
		<!--- This only works if the primary key is an integer field --->
		<cfquery datasource="#this._dsn#" name="q">
			SELECT last_insert_rowid() id
		</cfquery>
		<cfset this.id=q.id>
	</cfif>
</cffunction>

<cffunction name="DbUpdate"
	access="private" output="false" returnType="void"
	hint="Update a record (write changes to the database).">

	<cfargument name="IDColumnName" type="string" default="id"
		hint="Name of primary key column">
	
	<cfset var i="">
	<cfset var changes="">
	<cfset var comma="">
	<cfset var q="">

	<cfloop index="i" list="#schema[this._table]._columnNames#">
		<cfif (Compare(this[i], oldValues[i]) NEQ 0) AND (i NEQ "id")>
			<cfset changes=ListAppend(changes, i)>
		</cfif>
	</cfloop>
	<cfif Len(changes) EQ 0><cfreturn></cfif>

	<cfquery datasource="#this._dsn#">
		UPDATE "#this._table#" SET
		<cfloop index="i" list="#changes#">
			#comma# "#i#"=#Param(this[i], schema[this._table][i].class)#<cfset comma=",">
		</cfloop>
		WHERE "#Arguments.IDColumnName#"=#Param(
			this[Arguments.IDColumnName], schema[this._table][Arguments.IDColumnName].class
		)#
	</cfquery>
</cffunction>

<cffunction name="Param"
	access="private" output="false" returnType="string"
	hint="Encodes a string or numeric value for SQLite">

	<cfargument name="value" hint="Value to be encoded as an SQLite expression">
	<cfargument name="class" default="TEXT" hint="SQLite storage class name">

	<cfif Len(Arguments.value) EQ 0><cfreturn "NULL"></cfif>

	<cfif Arguments.class EQ "TEXT" OR Arguments.class EQ "BLOB" OR Arguments.class EQ "NONE">
		<cfreturn "'" & Replace(value, "'", "''", "all") & "'">
	</cfif>

	<cfif NOT IsNumeric(Arguments.value)><cfthrow message="Not a numeric value"></cfif>

	<cfif Arguments.class EQ "REAL" OR Arguments.class EQ "NUMERIC">
		<cfreturn Val(Arguments.value)>
	</cfif>
	
	<!--- INTEGER --->
	<cfreturn Int(Arguments.value)>
</cffunction>

</cfcomponent>