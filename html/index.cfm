<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
	<meta http-equiv="Content-Type" content="text/html;charset=utf-8" />
	<title>cfsqlite Test Page</title>
	<style type="text/css">
	</style>
</head>
<body>

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

<p><a href="vars.cfm">Inspect variables</a></p>

</body>
</html>
