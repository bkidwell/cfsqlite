<cfcomponent output="false" hint="<br />

<p><b>cfsqlite</b> version 0.1 &ndash; Handles setting up access to SQLite
database files from ColdFusion.</p>

<p>See documentation <a href=""https://github.com/bkidwell/cfsqlite"">online</a>
or the <b>README.html</b> included with this library.</p>

<p>Copyright &copy; 2011 Brendan Kidwell</p>

<p>Permission to use, copy, modify, and/or distribute this software for any
purpose with or without fee is hereby granted, provided that the above copyright
notice and this permission notice appear in all copies.</p>

<p>THE SOFTWARE IS PROVIDED &quot;AS IS&quot; AND THE AUTHOR DISCLAIMS ALL
WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER
RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT,
NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE
USE OR PERFORMANCE OF THIS SOFTWARE.</p>

">

<cfproperty name="Ready" type="boolean"
	hint="Component was successfully initialized">	
<cfproperty name="ApplicationName" type="struct"
	hint="Current Application Name">
<cfproperty name="DSN" type="struct"
	hint="Cache of already created/found Data Source Names">
<cfproperty name="DsnPrefix" type="string" default="sqlite"
	hint="Prefix for all SQLite data source names">

<cfset TAB=Chr(9)>
<cfset HTML_BEGIN="<!DOCTYPE html PUBLIC ""-//W3C//DTD XHTML 1.0 Transitional//EN""
""http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"">
<html xmlns=""http://www.w3.org/1999/xhtml"">">
<cfset HTML_END="</html>">

<cfset this.Ready=false>

<!---
	This key will be used to encrypt the /CFIDE Administration username and
	password in Session scope. Note, this is NOT ACTUALLY SECURE; it just
	prevents casual viewing of the username and password if you inspect the
	Session scope.
--->
<cfset CREDENTIALS_AES_KEY="H8lLVJwq9G9sJoyYVub0Ew==">

<cffunction name="Msg_SqliteNotFound"
	access="private" output="false" returnType="string"
	hint="Error message: SQLite library not found">

	<cfargument name="TargetFolder" type="string" required="true"
		hint="Where to install sqlite-*.jar">
	<cfset var r="">
	<cfsavecontent variable="r"><cfoutput>

	#HTML_BEGIN#
	<head>
		<title>#this.ApplicationName# &ndash; SQLite Setup Error</title>
	</head>
	<body>
	
	<p style="color: Red;"><b>SQLite Setup Error</b></p>
	
	<p>SQLite JDBC library required by this application was not found. Please
	do the following:</p>

	<ol>
		<li>Download <b>sqlite-*.jar</b> from
		<a href="http://www.zentus.com/sqlitejdbc/">www.zentus.com/sqlitejdbc</a>
		or from the <a href="https://github.com/bkidwell/cfsqlite/lib">cfsqlite web site</a>.
		</li>
		<li>Place the jar file in &quot;#Arguments.TargetFolder#&quot;.</li>
		<li>Restart your ColdFusion application server.</li>
	</ol>

	</body>
	#HTML_END#

	</cfoutput></cfsavecontent>
	<cfreturn Trim(r)>
</cffunction>

<cffunction name="Msg_CfideLogin"
	access="private" output="false" returnType="string"
	hint="Form: Input ColdFusion CFIDE login">

	<cfargument name="File" type="string"
		hint="Full fath to SQLite database file">
	<cfargument name="BadCredentials" type="boolean" required="true"
		hint="Credentials were entered but were invalid?">
	<cfargument name="Username" type="string" default=""
		hint="Current username value">
	<cfargument name="Password" type="string" default=""
		hint="Current password value">
	<cfset var r="">
	<cfsavecontent variable="r"><cfoutput>

	#HTML_BEGIN#
	<head>
		<title>#this.ApplicationName# &ndash; SQLite Setup &ndash; CFIDE Login</title>
	</head>
	<body>
	<p style="color: Red;">SQLite Setup: CFIDE Login</b></p>
	
	<p>The file,<br />
	&nbsp; &nbsp; &nbsp;<i>#Arguments.File#</i><br />
	required by <b>#this.ApplicationName#</b>, hasn't been installed as a Data
	Source in ColdFusion yet.</p>
	
	<p>Please provide credentials for the ColdFusion CFIDE Administration screen,
	in order to install the database.</p>
	
	<cfif Arguments.BadCredentials>
	<p style="color: Red;"><i>Bad username or password. Please try again.</i></p>
	</cfif>
	
	<form method="POST" action="#CGI.SCRIPT_NAME#?#CGI.QUERY_STRING#"><table>
		<tr><td>Username:</td>
		<td><input type="text" name="sqlite_cfide_username" value="#Arguments.Username#"></td></tr>
		<tr><td>Password:</td>
		<td><input type="password" name="sqlite_cfide_password" value="#Arguments.Password#"></td></tr>
		<tr><td colspan="2" align="right"><input type="submit" value="Create Datasource">
	</table></form>
	</body></html>
	#HTML_END#

	</cfoutput></cfsavecontent>
	<cfreturn Trim(r)>
</cffunction>

<cffunction name="Init"
	access="public" output="false" returnType="cfsqlite"
	hint="<b style=""color: Red;"">This method must be called before the
	component can be used.</b>">
	
	<cfargument name="ApplicationName" type="string" required="true"
		hint="The name of the current application">
	<cfargument name="GlobalContainer" default="##Application##"
		hint="(<b>struct</b>) Where to store application-level global singleton instance of this
		component">
	<cfargument name="DsnPrefix" default="sqlite" type="string"
		hint="Prefix for all SQLite data source names">

	<cfif NOT IsStruct(Arguments.GlobalContainer)>
		<cfset Arguments.GlobalContainer=Application>
	</cfif>

	<!--- append "?resetcfsqlite=1" to URL to reset while debugging --->
	<cfif IsDefined("Arguments.GlobalContainer.cfsqlite") AND NOT IsDefined("URL.resetcfsqlite")>
		<cfreturn Arguments.GlobalContainer.cfsqlite>
	</cfif>
	
	<cflock timeout="90" scope="Application" type="exclusive">
		<cfset this.ApplicationName=Arguments.ApplicationName>
		<cfset FindSqlite()>
		<cfset this.DsnPrefix=Arguments.DsnPrefix>
		<cfset this.DSN=StructNew()>
		<cfset this.Ready=true>

		<!--- Successfully initialized the singleton instance of this component --->
		<cfset Arguments.GlobalContainer.cfsqlite=this>
	</cflock>

	<cfreturn this>
</cffunction>

<cffunction name="FindSqlite"
	access="private" output="false" returnType="void"
	hint="Ensure that the SQLite JDBC library is loadable.">
	
	<cfset var sys=CreateObject("java", "java.lang.System")>
	<cfset var pathSep="">
	<cfset var path="">
	<cfset var test="">
	
	<cftry>
		<cfset test=CreateObject("java", "org.sqlite.JDBC")>
		<cfcatch>
			<!--- Couldn't instantiate "org.sqlite.JDBC" class --->
			<cfcontent reset="true">
			<cfset pathSep=sys.getProperty("file.separator")>
			<cfset path=sys.getProperty("java.home") & pathSep & "lib" & pathSep & "ext">

			<!--- Display help message and abort page --->
			<cfoutput>#Msg_SqliteNotFound(path)#</cfoutput>
			<cfabort>
		</cfcatch>
	</cftry>
</cffunction>
	
<cffunction name="GetDSN"
	access="public" output="false" returnType="string"
	hint="Get a DSN for an SQLite database file. This method can be called as
	many times as needed to setup more than one database file.">

	<cfargument name="File" type="string" hint="Full fath to SQLite database file">
	<cfset var key="">
	<cfset var dbName="">
	<cfset var dsn="">
	<cfset var dsnExists=false>
	<cfset var dsnPointsToFile=false>
	<cfset var q="">
	
	<cfif NOT this.Ready>
		<cfabort showerror="cfsqlite is not ready. You must call Init() first.">
	</cfif>

	<!--- Make a hash key from filename; remove "/", "\", and ".". --->
	<cfset key=ReReplace(Arguments.file, "[\\/\.]", "_", "all")>

	<cfif IsDefined("this.DSN.#key#")>
		<!--- DSN has already been setup in this application lifecycle --->
		<cfreturn this.DSN[key]>
	</cfif>

	<cflock timeout="90" scope="Application" type="exclusive">
	
		<cfset dbName=GetFileFromPath(Arguments.file)>
		<cfset dbName=ListDeleteAt(dbName, ListLen(dbName, "."), ".")>
		<cfset dsn="#this.DsnPrefix#.#this.applicationName#.#dbName#">
	
		<cftry>
			<!--- Can we access the database? --->
			<cfquery datasource="#dsn#">SELECT 1</cfquery>
			<cfset dsnExists=true>
			<cfcatch></cfcatch>
		</cftry>
		
		<cfif NOT dsnExists>
			<!---
			This will be called at least twice on two different requests:
			1. Prompt user for login and password.
			2. Actually create Data Source.
			--->
			<cfset CreateDatasource(Arguments.File, dsn)>
		</cfif>

		<!--- Data Source successfully created or located; store result in cache. --->
		<cfset this.DSN[key]=dsn>

	</cflock>

	<cfreturn dsn>
</cffunction>

<cffunction name="CreateDatasource"
	access="private" output="false" returnType="void"
	hint="Display and consume form to login to CFIDE API and create data source for this SQLite database">

	<cfargument name="File" type="string" hint="Full fath to SQLite database file">
	<cfargument name="DSN" type="string" hint="CF data source name">
	<cfset var username="">
	<cfset var password="">
	<cfset var badCredentials=false>
	<cfset var tmp="">
	<cfset var adminObj="">
	<cfset var dbObj="">
	<cfset var url="">
	
	<cfif IsDefined("Session.sqlite_cfide_credentials") AND Len(Session.sqlite_cfide_credentials) GT 0>
		<cfset tmp=Decrypt(Session.sqlite_cfide_credentials, CREDENTIALS_AES_KEY, "AES")>
		<cfset username=ListFirst(tmp, TAB)>
		<cfset password=ListLast(tmp, TAB)>
	</cfif>
	<cfif IsDefined("Form.sqlite_cfide_username")>
		<cfset username=Form.sqlite_cfide_username>
		<cfset password=Form.sqlite_cfide_password>
		<cfset Session.sqlite_cfide_credentials=Encrypt(
			"#username##TAB##password#", CREDENTIALS_AES_KEY, "AES"
		)>
	</cfif>
	
	<cfif Len(username) GT 0>
		<cfset adminObj=CreateObject("component", "cfide.adminapi.administrator")>
		<cfif adminObj.login(password, username)>
			<cfset dbObj=CreateObject("component", "cfide.adminapi.datasource")>
			<cfset dbObj.setOther(
				name=Arguments.DSN,
				url="jdbc:sqlite:#REReplace(Arguments.File, "\\", "/", "all")#",
				class="org.sqlite.JDBC",
				driver="SQLite JDBC Driver",
				description="SQLite file ""#Arguments.File#"" -- This Data " &
				"Source was automatically created by cfsqlite for the " &
				"application ""#this.ApplicationName#"". It may be safely " &
				"deleted if the application is no longer in use."
			)>
			<!--- Success! --->
			<cfreturn>
		<cfelse>
			<cfset badCredentials=true>
		</cfif>
	</cfif>
	
	<cfif Len(username) EQ 0><cfset username="admin"></cfif>

	<!--- Display credentials form and abort page --->
	<cfcontent reset="true">
	<cfoutput>#Msg_CfideLogin(
		Arguments.File, badCredentials, username, password
	)#</cfoutput>
	<cfabort>
</cffunction>

</cfcomponent>