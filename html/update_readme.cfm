<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<!---

update_readme.cfm

Updates README.md from the first comment in lib/cfsqlite.cfc -- So we can keep
the whole library and its documentation in one place in the source tree.

--->
<head>
	<meta http-equiv="Content-Type" content="text/html;charset=utf-8" />
	<title>cfsqlite - Update README.md File</title>
	<style type="text/css">
	</style>
</head>
<body>

<cffile action="read" file="#ExpandPath("../lib/cfsqlite.cfc")#" variable="text"/>

<cfset md=REMatch("<" & "!---(.*?)---" & ">", text)>
<cfset md=md[1]>
<cfset md=Trim(Mid(md, 6, Len(md) - 9))>
<!--- md is original comment source now --->

<!--- fix newlines if any are wrong --->
<cfset md=Replace(md, "#Chr(13)##Chr(10)#", Chr(10), "all")>

<!--- fix comments --->
<cfset md=ReplaceNoCase(md, "[comment]", "<" & "!---", "all")>
<cfset md=ReplaceNoCase(md, "[/comment]", "---" & ">", "all")>

<!--- fix paragraphs --->
<cfset md=REReplace(md, "(\S)\n(\S)", "\1 \2", "all")>

<cfform><cftextarea name="output" value="#md#" style="width: 100%; height: 40em;" /></cfform>

<cffile action="write" file="#ExpandPath("../README.md")#" output="#md#" />

<p>README.md has been updated.</p>

</body>
</html>
