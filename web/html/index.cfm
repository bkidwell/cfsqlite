<cfsetting enableCFoutputOnly="true">
<!---

index.cfm

* Demonstrates a comment wall using cfsqlite

--->

<cfset display_message="">

<cfif IsDefined("URL.clear")>
	<cfset Request.TestSchema.DropAllObjects()>
	<cfset display_message="<p><b style=""color: red;"">Database has been
	cleared.</b></p>">
</cfif>

<cfif IsDefined("URL.create")>
	<cfset Request.TestSchema
		.CreateTable(
			"comment",
			"id pk",
			"date text",
			"author text",
			"text text"
		)
		.CreateIndex(
			"comment_author",
			"comment",
			"author"
		)
		.CreateTable(
			"config",
			"key text primary key",
			"value text"
		)
		.Refresh()
	>
	<cfset rec=Request.TestSchema.Record("config")>
	<cfset rec.key="Application Title">
	<cfset rec.value="cfsqlite Test Web Site">
	<cfset rec.Save("key")><!--- specifying primary key name because it's not the default name 'id' --->
	<cfset display_message="<p><b style=""color: red;"">Database has been
	created.</b></p>">
</cfif>

<cfif IsDefined("Form.text")>
	<cfset rec=Request.TestSchema.Record("comment")>
	<cfset rec.date=Now()>
	<cfset rec.author=Form.author>
	<cfset rec.text=Form.text>
	<cfset rec.Save()>
</cfif>

<cfset AppName="">
<cftry>
	<cfquery name="comments" datasource="#Request.TestDSN#">
		SELECT * FROM comment ORDER BY date
	</cfquery>
	<cfset AppName=Request.TestSchema.Record("config").Load("Application Title", "key").value>
	<cfcatch>
		<cfset display_message="<p><b style=""color: red;"">Error: You probably
		haven't created your tables yet</b></p>">
	</cfcatch>
</cftry>

<cfoutput><!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
	<meta http-equiv="Content-Type" content="text/html;charset=utf-8" />
	<title>#AppName#</title>
	<style type="text/css">
	</style>
</head>
<body>

<h1>#AppName#</h1>

#display_message#

<p>
<a href="?">Home</a> |
<a href="?clear">Clear database</a> |
<a href="?create">Create tables</a> |
<a href="documentation.cfm">View/update documentation</a>
</p>

<cfif IsDefined("comments")>
	<cfdump var="#comments#" label="Comment table">
</cfif>

<form action="?post" method="post">
<p>
	Author <input type="text" name="author" /><br />
	<textarea name="text" style="width: 40em; height: 10em;"></textarea><br />
	<input type="submit" value="Submit Comment">
</p>
</form>

</body>
</html></cfoutput>