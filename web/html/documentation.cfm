<cfsetting enableCFoutputOnly="true">
<!---

update_docs.cfm

* Updates README.html from README.md
* Updates doc/* from inline documentation in src/*.cfc

--->

<cfset display_message="">
<cfset mdLib="">

<cffunction name="makeHtml" output="false">
	<cfargument name="title">
	<cfargument name="bodyMarkdown">
	<cfset var html="">
	<cfsavecontent variable="html"><cfoutput>
		<html>
		<head>
		<meta http-equiv=""Content-Type"" content=""text/html; charset=utf-8"">
		<title>#Arguments.title#</title>
		</title>
		<style>
			h1 { font-family: sans-serif; font-size: 130%; }
			h2 { font-family: sans-serif; font-size: 115%; }
		</style>
		</head><body>
		#mdLib.markdown(Arguments.bodyMarkdown)#
		</body>
		</html>
	</cfoutput></cfsavecontent>
	<cfreturn REReplace(Trim(html), "\n\t\t", Chr(10), "all")>
</cffunction>

<cffunction name="extractMarkdown" output="false">
	<cfargument name="source">
	<cfset var md="">
	
	<cfset md=REMatch("<" & "!---(.*?)---" & ">", source)>
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
	
	<cfreturn md>
</cffunction>

<cfif IsDefined("URL.update") AND URL.update EQ 1>
	<cfset mdLib=CreateObject("component", "app.ext.javaloader.JavaLoader").init(
		ListToArray(ExpandPath("../ext/markdownj-1.0.2b4-0.3.0.jar"))
	).create("com.petebevin.markdown.MarkdownProcessor")>

	<cffile action="read" file="#ExpandPath("../../src/cfsqlite.cfc")#" variable="src_cfsqlite"/>
	<cfset md_cfsqlite=extractMarkdown(src_cfsqlite)>
	<cfset html_cfsqlite=makeHtml("cfsqlite.cfc", md_cfsqlite)>

	<cffile action="write" file="#ExpandPath("../../doc/cfsqlite.md")#" output="#md_cfsqlite#" />
	<cffile action="write" file="#ExpandPath("../../doc/cfsqlite.html")#" output="#html_cfsqlite#" />
	
	<cffile action="read" file="#ExpandPath("../../src/cfsqliteschema.cfc")#" variable="src_cfsqliteschema"/>
	<cfset md_cfsqliteschema=extractMarkdown(src_cfsqliteschema)>
	<cfset html_cfsqliteschema=makeHtml("cfsqlite.cfc", md_cfsqliteschema)>

	<cffile action="write" file="#ExpandPath("../../doc/cfsqliteschema.md")#" output="#md_cfsqliteschema#" />
	<cffile action="write" file="#ExpandPath("../../doc/cfsqliteschema.html")#" output="#html_cfsqliteschema#" />

	<cffile action="read" file="#ExpandPath("../../README.md")#" variable="md_readme"/>
	<cfset html_readme=makeHtml("README for cfsqlite", md_readme)>

	<cffile action="write" file="#ExpandPath("../../README.html")#" output="#html_readme#" />

	<cfset display_message="<p><b style=""color: red;"">Documentation files have
		been updates from sources.</b></p>">
</cfif>

<cfif IsDefined("URL.file")>
	<cfset path=ExpandPath("../../" & URL.file)>
	<cffile action="read" file="#path#" variable="data">

	<cfif Right(URL.file, 3) EQ ".md">
		<cfoutput><html>
			<head><title>#URL.file#</title></head>
			<body style="white-space: pre-wrap; font-family: monospace;"
			>#HTMLEditFormat(data)#</body></body>
		</html></cfoutput>
		<cfabort>
	<cfelse>
		<cfoutput>#data#</cfoutput>
		<cfabort>
	</cfif>
</cfif>

<cfoutput><!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
	<meta http-equiv="Content-Type" content="text/html;charset=utf-8" />
	<title>cfsqlite - Documentation</title>
</head>
<body>

<h1>cfsqlite Documentation</h1>

#display_message#

<ul>
<li>
	README:
	<a href="?file=README.md">md</a> |
	<a href="?file=README.html">html</a>
</li>
<li>
	doc/cfsqlite:
	<a href="?file=doc/cfsqlite.md">md</a> |
	<a href="?file=doc/cfsqlite.html">html</a>
</li>
<li>
	doc/cfsqliteschema:
	<a href="?file=doc/cfsqliteschema.md">md</a> |
	<a href="?file=doc/cfsqliteschema.html">html</a>
</li>
</ul>

<p><a href="?update=1">Update documentation from sources</a></p>

</body>
</html></cfoutput>
