<cfcomponent output="false"
	hint="Represents a single record in an SQLite database">

	<cfproperty name="_dsn" type="string" hint="Datasource name">
	<cfproperty name="_tableName" type="string" hint="Table name">
	<cfproperty name="_oldValues" type="struct" hint="Struct of old values for each column">
	<cfset schema=""><!--- The schema for the chosen DSN --->

	<cffunction name="Init"
		access="public" output="false" returnType="sqliterecord"
		hint="Constructor">
	
		<cfargument name="table" type="string" required="true"
			hint="Table name">
		<cfargument name="dsn" type="string" default="#Request.DSN#"
			hint="Data source name">
		<cfset var i="">
		<cfset var col="">
				
		<cfif Not IsDefined("Application.sqliterecord")><cflock timeout="90" scope="Application" type="exclusive">
			<cfset Application.sqliterecord=StructNew()>
		</cflock></cfif>
		<cfif Not StructKeyExists(Application.sqliterecord, arguments.dsn)><cflock timeout="90" scope="Application" type="exclusive">
			<cfset Application.sqliterecord[Arguments.dsn]=Request.Component("app.lib.sqliteschema").Init(Arguments.dsn)>
		</cflock></cfif>

		<cfset this._dsn=Arguments.dsn>
		<cfset schema=Application.sqliterecord[this._dsn]>
		<cfset this._tableName=schema[Arguments.table]._name>
		<cfset this._oldValues=StructNew()>
		<cfloop index="i" list="#schema[Arguments.table]._columnNames#">
			<cfset this._oldValues[i]="">
			<cfset this[i]="">
		</cfloop>

		<cfreturn this>
	</cffunction>
	
	<cffunction name="Load"
		access="public" output="false" returnType="sqliterecord"
		hint="Load a record with the given id">
		
		<cfargument name="id" type="numeric" required="true"
			hint="Value in 'id' column">
		<cfset var q="">
		<cfset var i="">
		
		<cfquery datasource="#this._dsn#" name="q">
			SELECT * FROM "#this._tableName#" WHERE id=#Arguments.id#
		</cfquery>
		<cfloop index="i" list="#schema[this._tableName]._columnNames#">
			<cfset this[i]=q[i][1]>
			<cfset this._oldValues[i]=this[i]>
		</cfloop>

		<cfreturn this>
	</cffunction>
	
	<cffunction name="Save"
		access="public" output="false" returnType="sqliterecord"
		hint="Save a record">
		
		<cfif Len(this.id) EQ 0>
			<cfset DbInsert()>
		<cfelse>
			<cfset DbUpdate()>
		</cfif>
		<cfset Load(this.id)>

		<cfreturn this>
	</cffunction>
	
	<cffunction name="DbInsert"
		access="private" output="false" returnType="void"
		hint="Insert a record">
		
		<cfset var i="">
		<cfset var changes="">
		<cfset var comma="">
		<cfset var q="">
	
		<cfloop index="i" list="#schema[this._tableName]._columnNames#">
			<cfif Compare(this[i], this._oldValues[i]) NEQ 0>
				<cfset changes=ListAppend(changes, i)>
			</cfif>
		</cfloop>
	
		<cfquery datasource="#this._dsn#">
			INSERT INTO "#this._tableName#" (
			<cfset comma=""><cfloop index="i" list="#changes#">
				#comma# "#i#"<cfset comma=",">
			</cfloop>
			) VALUES (
			<cfset comma=""><cfloop index="i" list="#changes#">
				#comma# #Param(this[i], schema[this._tableName][i].class)#<cfset comma=",">
			</cfloop>
			)
		</cfquery>
		<cfquery datasource="#this._dsn#" name="q">
			<!---
			SELECT TOP 1 id FROM "#this._tableName#" ORDER BY id DESC
			--->
			SELECT last_insert_rowid() id
		</cfquery>
		<cfset this.id=q.id>
	</cffunction>

	<cffunction name="DbUpdate"
		access="private" output="false" returnType="void"
		hint="Update a record">
		
		<cfset var i="">
		<cfset var changes="">
		<cfset var comma="">
		<cfset var q="">
	
		<cfloop index="i" list="#schema[this._tableName]._columnNames#">
			<cfif (Compare(this[i], this._oldValues[i]) NEQ 0) AND (i NEQ "id")>
				<cfset changes=ListAppend(changes, i)>
			</cfif>
		</cfloop>
		<cfif Len(changes) EQ 0><cfreturn></cfif>
	
		<cfquery datasource="#this._dsn#">
			UPDATE "#this._tableName#" SET
			<cfloop index="i" list="#changes#">
				#comma# "#i#"=#Param(this[i], schema[this._tableName][i].class)#<cfset comma=",">
			</cfloop>
			WHERE id=#this.id#
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