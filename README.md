**NAME**
 
**cfsqlite** – Handles setting up access to SQLite database files from ColdFusion.
  
**SYNOPSIS**

    <cfset Request.dsn =
        CreateObject("component", "MYAPP.lib.sqlite").Init()
        .GetDSN( ExpandPath("../database/DATABASE_NAME.db"), this.name )>
  
**DESCRIPTION**

**cfsqlite** is a ColdFusion library that facilitates quick setup of [SQLite](http://sqlite.org/) databases inside your application. If you call **cfsqlite.GetDSN()** at the start of each request, it will do the following:

1.  Act as a singleton object (only one instance per application; save time and memory).

2.  Ensure that [SqliteJDBC](http://www.zentus.com/sqlitejdbc/) is available in the Java "extensions" folder and is loadable. If not, it displays an error page prompting the user to download the **sqlitejdbc** to ColdFusion's JRE's "ext" folder.

3.  Compute a standardized ColdFusion Data Source Name ("sqlite.**APPNAME**.**BASE\_FILENAME**") and determine if there already a database attached there. If the Data Source Name doesn't exist, it prompts the user for a username and password for the **/CFIDE** Administration interface and installs the database.

... and if **cfsqlite** wasn't interrupted by any setup tasks, it will return the Data Source Name to use in your queries.

**cfsqlite** should only be used in a development or demonstration environment, unless you're sure you know what you're doing. SQLite does not handle multiple concurrent users well. SQLite's strength is in integrating the database engine into a library running in the application's process, thereby allowing developers to get up and running with a project quickly without setting up a separate enterprise database engine. It's great for distributing sample/howto code.

**EXAMPLE**

    <!--- In Application.onRequestStart() event handler... --->
    
    <cfset Request.dsn =
        CreateObject("component", "MYAPP.lib.sqlite").Init()
        .GetDSN( ExpandPath("../database/sample.db"), this.name )>`
    
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

**NOTES**

**cfsqlite** will create ColdFusion Data Sources, but it will never delete them automatically. That's up to you.

**cfsqlite** will not create SQLite database files for you. Use your favorite standalone SQLite database browser/editor to do that.

**Do not put your SQLite database file a directory that is web-accessible!**

**REQUIREMENTS**

ColdFusion 8

**HISTORY**

Version 0.1 – initial release

**HOMEPAGE**

[cfsqlite web site](https://github.com/bkidwell/cfsqlite)

**SEE ALSO**

[cfsqlite API documentation](doc/api.html)

[SQLite](http://sqlite.org/) web site; [syntax documentation](http://sqlite.org/lang.html).

[sqlitejdbc](http://www.zentus.com/sqlitejdbc/) JDBC driver for Java.

**AUTHOR**

Brendan Kidwell <[brendan@glump.net](mailto:brendan@glump.net)\>.

Please drop me a line if you find **cfsqlite** useful (or if you find a problem.)

**COPYRIGHT**

Copyright © 2011 Brendan Kidwell

Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted, provided that the above copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
