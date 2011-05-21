# cfsqlite.cfc from cfsqlite version 1.0.1

Handles setting up access to SQLite database files as Data Sources in ColdFusion.

## DESCRIPTION

**cfsqlite.cfc** can be called at the start of each request (in the `onRequestStart()` Application event) to map a database filename to a ColdFusion Data Source Name, for example:

    <cfset Request.dsn =
        CreateObject("component", "MYAPP.lib.cfsqlite").Init(this.name)
        .GetDSN( ExpandPath("../database/DATABASE_NAME.db") )>

and that's all you have to do. Now you can use `#Request.dsn#` as your `datasource` in any `cfquery` call anywhere in your application.

Behind the scenes, cfsqlite does a few things:

1. Make sure that SQLiteJDBC is available in ColdFusion's JRE's `lib/ext` folder. If not, the request is aborted and an error message instructs the user to install the library. (This library is included in the distribution of cfsqlite, but it can't be installed automatically because normally ColdFusion applications do not have sufficient privileges to write to the ColdFusion engine's files.)

2. If it hasn't already done so, cfsqlite installs the Data Source Name in the ColdFusion settings using a predictable name based upon the application name and database filename. In order to install the Data Source Name, cfsqlite aborts the request and prompts the user for credentials to authenticate to the `cfide.adminapi` back-end.

3. If the above two conditions are satisfied, the request continues normally and cfsqlite returns the Data Source Name.

After the first database access in an application instance, the Data Source Name is cached by cfsqlite, so calling `GetDSN()` at the start of each request does not incur any delay.

## EXAMPLE

    <!--- In Application.onRequestStart() event handler... --->
    
    <cfset Request.dsn =
        CreateObject("component", "MYAPP.lib.cfsqlite").Init(this.name)
        .GetDSN( ExpandPath("../database/stats.db"), this.name )>`
    
    <!--- In your page... --->
	
    <cfquery name="data" datasource="#Request.dsn#">
        SELECT value FROM data WHERE key='hit_count'
    </cfquery>
    
    <cfset hit_count=data.value + 1>
    <cfquery datasource="#Request.dsn#">
        UPDATE data SET value=#hit_count# WHERE key='hit_count'
    </cfquery>
    
    <cfoutput><p>
        Current hit count: #hit_count#
    </p></cfoutput>

## NOTES

cfsqlite will create ColdFusion Data Sources, but it will never delete them automatically. That's up to you.

<b style="color: red;">Do not put your SQLite database file in a folder that is web-accessible!</b>

## REQUIREMENTS

ColdFusion 8

## SEE ALSO

[SQLite](http://sqlite.org/) web site; [syntax documentation](http://sqlite.org/lang.html).

[sqlitejdbc](http://www.zentus.com/sqlitejdbc/) JDBC driver for Java.

## PROPERTIES

<dl><dt><i>struct</i> <b>ApplicationName</b></dt>
<dd>Current Application Name.</dd>
<dt><i>struct</i> <b>DSN</b></dt>
<dd>Cache of already created/found Data Source names.</dd>
<dt><i>string</i> <b>DsnPrefix</b></dt>
<dd>Prefix for all SQLite Data Source names.</dd>
<dt><i>boolean</i> <b>Ready</b></dt>
<dd>Component was successfully initialized.</dd></dl>

## FUNCTIONS

### GetDSN

`GetDSN(File)`

Get a DSN for an SQLite database file. This method can be called as many times as needed to setup more than one database file.

access: `public`<br>
returns: `string`

<dl><dt><code>string</code> <b><code>File</code></b></dt><dd>Full fath to SQLite database file. Complete path and file will be created if they don't already exist.</dd></dl>

### Init

`Init(ApplicationName, GlobalContainer, DsnPrefix)`

Constructor.

access: `public`<br>
returns: `cfsqlite`

<dl><dt><code>string</code> <b><code>ApplicationName</code></b></dt><dd>The name of the current application</dd>

<dt><i>optional</i> <b><code>GlobalContainer</code></b> <span style="color: Gray;">(default "#Application#")</span></dt><dd>(<b>struct</b>) Where to store application-level global singleton instance of this component</dd>

<dt><i>optional</i> <code>string</code> <b><code>DsnPrefix</code></b> <span style="color: Gray;">(default "sqlite")</span></dt><dd>Prefix for all SQLite data source names</dd></dl>
