<cfcomponent output="false">
	
<!--- Application name, should be unique --->
<cfset this.name = "cfsqlite">

<cfset this.sessionManagement = true>
<cfset this.sessionTimeout = createTimeSpan(0,12,0,0)>
<cfset this.setClientCookies = true>
<cfset this.setDomainCookies = false>
<cfset this.mappings = structNew()>
<cfset this.customtagpaths = "">
<cfset this.mappings["/app"]=ExpandPath("..")>
<cfset this.mappings["/app_cfsqlite"]=ExpandPath("../../src")>

<cffunction name="onRequestStart" returnType="boolean" output="false">
	<cfargument name="thePage" type="string" required="true">
	<cfset var sqlite="">

	<cfset sqlite=CreateObject("component", "app_cfsqlite.cfsqlite").Init(this.name)>
	<cfset Request.TestDSN=sqlite.GetDSN(ExpandPath("../database/test.db"))>
	<cfset Request.TestSchema=CreateObject("component", "app_cfsqlite.cfsqliteschema").Init(Request.TestDSN)>
	<!---
	<cfset Request.DSN=sqlite.GetDSN(ExpandPath("../database/sample.db"))>
	--->

	<cfreturn true>
</cffunction>

</cfcomponent>