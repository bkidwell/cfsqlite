<cfset schema=CreateObject("component", "app_cfsqlite.cfsqliteschema").Init(Request.TestDSN)>

<cfset schema.DropAllObjects()>
<cfset schema.CreateTable(
	"comment",
	"id PK",
	"date TEXT",
	"author INTEGER",
	"text TEXT"
)>
<cfset schema.CreateIndex("comment_author", "comment", "author")>
<cfset schema.Refresh()>

<cfdump var="#schema#">

<cfset rec=schema.Record("comment")>
<cfset rec.text="Comment!!!">
<cfset rec.Save()>

<cfdump var="#rec#">