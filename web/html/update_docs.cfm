<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<!---

update_docs.cfm

Updates README.* and doc/cfsqlite.* from the first comment in lib/cfsqlite.cfc
-- So we can keep the whole library and its documentation in one place in the
source tree.

--->
<head>
	<meta http-equiv="Content-Type" content="text/html;charset=utf-8" />
	<title>cfsqlite - Update README.md File</title>
</head>
<body>

<cfset html_head_1="<html>
<head>
<meta http-equiv=""Content-Type"" content=""text/html; charset=utf-8"">
<title>">
<cfset html_head_2="</title>
<style>
	h1 { font-family: sans-serif; font-size: 130%; }
	h2 { font-family: sans-serif; font-size: 115%; }
</style>
</head><body>">
<cfset html_foot="</body></html>">

<!--- -----------------------------
Read and tweak Markdown source code
------------------------------ --->

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

<!--- ---------
Convert to HTML
---------- --->

<cfset mdLib=CreateObject("component", "app.ext.javaloader.JavaLoader").init(
	ListToArray(ExpandPath("../ext/markdownj-1.0.2b4-0.3.0.jar"))
).create("com.petebevin.markdown.MarkdownProcessor")>
<cfset html=mdLib.markdown(md)>
<cfset html="#html_head_1#cfsqlite.cfc#html_head_2##html##html_foot#">

<!--- -------------------
Save Markdown source code
-------------------- --->

<cfform><cftextarea name="output" value="#md#" style="width: 100%; height: 40em;" /></cfform>

<cffile action="write" file="#ExpandPath("../README.md")#" output="#md#" />
<cffile action="write" file="#ExpandPath("../README.html")#" output="#html#" />
<cffile action="write" file="#ExpandPath("../doc/cfsqlite.md")#" output="#md#" />
<cffile action="write" file="#ExpandPath("../doc/cfsqlite.html")#" output="#html#" />

<p>README.md and README.html have been updated.</p>

</body>
</html>
