<cfsetting enableCFoutputOnly="true">
<!---

documentation.cfm

* Updates README.html from README.md
* Updates doc/* from inline documentation in src/*.cfc

--->

<cfset LF=Chr(10)>
<cfset CR=Chr(13)>

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
			body { margin: 10px 30px; }
			h1 { font-family: sans-serif; font-size: 130%; margin-left: -20px; }
			h2 { font-family: sans-serif; font-size: 115%; margin-left: -20px; }
			h3 { font-family: sans-serif; font-size: 100%; margin-left: -20px; }
		</style>
		</head><body>
		#mdLib.markdown(Arguments.bodyMarkdown)#
		</body>
		</html>
	</cfoutput></cfsavecontent>
	<cfreturn REReplace(Trim(html), "\n\t\t", LF, "all")>
</cffunction>

<cffunction name="extractMarkdown" output="false">
	<cfargument name="source">
	<cfset var md="">
	
	<cfset md=REMatch("<" & "!---(.*?)---" & ">", source)>
	<cfset md=md[1]>
	<cfset md=Trim(Mid(md, 6, Len(md) - 9))>
	<!--- md is original comment source now --->
	
	<!--- fix newlines if any are wrong --->
	<cfset md=Replace(md, "#CR##LF#", LF, "all")>
	
	<!--- fix comments --->
	<cfset md=ReplaceNoCase(md, "[comment]", "<" & "!---", "all")>
	<cfset md=ReplaceNoCase(md, "[/comment]", "---" & ">", "all")>
	
	<!--- fix paragraphs --->
	<cfset md=REReplace(md, "(\S)\n(\S)", "\1 \2", "all")>
	
	<cfreturn md>
</cffunction>

<cffunction name="structByName" output="false">
	<cfargument name="objArray">
	<cfset var i="">
	<cfset var r=StructNew()>
	
	<cfset r.data=StructNew()>
	<cfloop index="i" array="#Arguments.objArray#">
		<cfset r.data[i.name]=i>
	</cfloop>
	<cfset r.keys=StructKeyArray(r.data)>
	<cfset ArraySort(r.keys, "textnocase")>
	<cfreturn r>
</cffunction>

<cffunction name="cleanHint" output="false">
	<cfargument name="md">
	
	<cfset md=Replace(md, CR & LF, LF, "all")>
	<cfset md=md.ReplaceAll("\n[\t ]*(\S)", "#LF#$1")>
	<cfset md=md.ReplaceAll("\n([^\n])", " $1")>
	<cfreturn md>
</cffunction>

<cffunction name="extractMetaData" output="false">
	<cfargument name="component">
	<cfset var data=GetComponentMetaData(Arguments.component)>
	<cfset var s_properties=ArrayNew(1)>
	<cfset var s_functions=ArrayNew(1)>
	<cfset var i="">
	<cfset var j="">
	<cfset var obj="">
	<cfset var tmpStruct="">
	<cfset var names="">
	<cfset var s_parms=ArrayNew(1)>
	<cfset var rtype="">
	<cfset var opt="">
	<cfset var p_default="">
	<cfset var p_type="">
	<cfset var f_hint="">
	<cfset var p_hint="">
	
	<cfset tmpStruct=structByName(data.properties)>
	<cfloop index="i" array="#tmpStruct.keys#">
		<cfset obj=tmpStruct.data[i]>
		<cfset p_type=""><cfif IsDefined("obj.type")><cfset p_type="<i>#obj.type#</i> "></cfif>
		<cfset p_hint=""><cfif IsDefined("obj.hint")><cfset p_hint=cleanHint(obj.hint)></cfif>
		<cfset ArrayAppend(s_properties,
			"<dt>#p_type#<b>#obj.name#</b></dt>" & LF &
			"<dd>#p_hint#</dd>"
		)>
	</cfloop>
	
	<cfset tmpStruct=structByName(data.functions)>
	<cfloop index="i" array="#tmpStruct.keys#">
		<cfset obj=tmpStruct.data[i]>
		<cfif obj.access EQ "public">
			<cfset s_parms=ArrayNew(1)>
			
			<cfloop index="j" array="#obj.parameters#">
				<cfset ArrayAppend(s_parms, j.name)>
			</cfloop>
			<cfset sig="`#obj.name#(#ArrayToList(s_parms, ", ")#)`">
			
			<cfset rtype="any">
			<cfif IsDefined("obj.returntype")><cfset rtype=obj.returntype></cfif>
			
			<cfset s_parms=ArrayNew(1)>
			
			<cfloop index="j" array="#obj.parameters#">
				<cfset opt="<i>optional</i> ">
				<cfif IsDefined("j.required") AND j.required><cfset opt=""></cfif>
				<cfset p_default="">
				<cfif IsDefined("j.default")><cfset p_default=" <span style=""color: Gray;"">(default ""#j.default#"")</span>"></cfif>
				<cfset p_type="">
				<cfif IsDefined("j.type")><cfset p_type="<code>#j.type#</code> "></cfif>
				<cfset p_hint="">
				<cfif IsDefined("j.hint")><cfset p_hint=cleanHint(j.hint)></cfif>
				<cfset ArrayAppend(s_parms,
					"<dt>#opt##p_type#<b><code>#j.name#</code></b>#p_default#</dt>" &
					"<dd>#p_hint#</dd>"
				)>
			</cfloop>
			<!---
			<cfif ArrayLen(obj.parameters) EQ 0>
				<cfset ArrayAppend(s_parms, "<dt><i>(none)</i></dt><dd></dd>")>
			</cfif>
			--->
			
			<cfset f_hint="">
			<cfif IsDefined("obj.hint")><cfset f_hint=cleanHint(obj.hint) & LF & LF></cfif>
			
			<cfset ArrayAppend(s_functions,
				"###### #obj.name##LF##LF#" &
				"#sig##LF##LF#" &
				f_hint &
				"access: `#obj.access#`<br>#LF#" &
				"returns: `#rtype#`#LF##LF#" &
				"<dl>#ArrayToList(s_parms, LF & LF)#</dl>"
			)>
		</cfif>
	</cfloop>
	<cfif ArrayLen(s_properties) EQ 0><cfset ArrayAppend(s_properties, "*(none)*")></cfif>
	<cfif ArrayLen(s_functions) EQ 0><cfset ArrayAppend(s_functions, "*(none)*")></cfif>
	<cfreturn
		"#### PROPERTIES" & LF & LF &
		"<dl>" & ArrayToList(s_properties, LF) & "</dl>" & LF & LF &
		"#### FUNCTIONS" & LF & LF &
		ArrayToList(s_functions, LF & LF)
	>
</cffunction>

<cfif IsDefined("URL.update") AND URL.update EQ 1>
	<cfset mdLib=CreateObject("component", "app.ext.javaloader.JavaLoader").init(
		ListToArray(ExpandPath("../ext/markdownj-1.0.2b4-0.3.0.jar"))
	).create("com.petebevin.markdown.MarkdownProcessor")>

	<cfloop index="f" list="cfsqlite,cfsqliteschema,cfsqliterecord">
		<cffile action="read" file="#ExpandPath("../../src/" & f & ".cfc")#" variable="src">
		<cfset md=extractMarkdown(src)>
		<cfset md=md & LF & LF & extractMetaData("app_cfsqlite.#f#")>
		<cfset html=makeHtml("#f#.cfc", md)>

		<cffile action="write" file="#ExpandPath("../../doc/" & f & ".md")#" output="#md#">
		<cffile action="write" file="#ExpandPath("../../doc/" & f & ".html")#" output="#html#">
	</cfloop>

	<cffile action="read" file="#ExpandPath("../../README.md")#" variable="md_readme">
	<cfset html_readme=makeHtml("README for cfsqlite", md_readme)>

	<cffile action="write" file="#ExpandPath("../../README.html")#" output="#html_readme#">

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
	doc/cfsqliterecord:
	<a href="?file=doc/cfsqliterecord.md">md</a> |
	<a href="?file=doc/cfsqliterecord.html">html</a>
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
