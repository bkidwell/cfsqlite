# cfsqlite version 1.0.1

Handles setting up access to SQLite database files as Data Sources in ColdFusion, and provides convenience functions for clearing and creating empty databases and also a rudimentary mapping of database rows to ColdFusion objects.

## DESCRIPTION

**cfsqlite.cfc** can be called at the start of each request (in the `onRequestStart()` Application event) to map a database filename to a ColdFusion Data Source Name, for example:

    <cfset Request.dsn =
        CreateObject("component", "MYAPP.lib.cfsqlite").Init(this.name)
        .GetDSN( ExpandPath("../database/DATABASE_NAME.db") )>

and that's all you have to do. Now you can use `#Request.dsn#` as your `datasource` in any `cfquery` call anywhere in your application.

**cfsqliteschema.cfc** provides some convenience functions related to SQLite:

* Creating tables and deleting all database objects -- so you don't have to distribute an empty database binary file as part of your application, and you can keep your database design in version controlled ColdFusion code.

**cfsqliterecord.cfc** is a rudimentary mapping of a SQLite database row to a ColdFusion object with `Load()` and `Save()` methods.

## INSTALLATION

To use cfsqlite in your application:

1. Copy `src/cfsqlite.cfc` into your application's `ext` or `lib` folder, or wherever you store external libraries. Do the same for `src/cfsqliteschema.cfc` and `src/cfsqliterecord.cfc` if you plan to use them.

2. Copy `ext/sqlitejdbc-v056.jar` to the `lib/ext` folder under your ColdFusion installation's JRE. If you're not sure where that is, just skip this step for now and the first time you try to use cfsqlite, it will tell you the appropriate folder to copy the JAR file to.

To run the demo/test/documentation web site included in the cfsqlite distribution:

1. Check out the entire source tree or download the `.zip` archive and extract to `$CFSQLITE_HOME` on your web server.

2. Create a mapping/alias/virtual directory in your web server that maps **/cfsqlite** to `$CFSQLITE_HOME/web/html`. The exact name of the mapping is not important. See your web server's documentation for details on how create a mapping if you don't know how.

3. Point your browser to the URL of the mapping you just created.

## REQUIREMENTS

ColdFusion 8

## HISTORY

Version 1.0.1 -- oops! more documentation fixes.

Version 1.0 -- added `cfsqliteschema.cfc` and `cfsqliterecord.cfc`; added automatic creation of empty database; cleaned up documentation; announced on Freshmeat.

Version 0.11 -- embedded documentation into component source code and cleaned up some bad URLs.

Version 0.10 -- initial release.

## HOMEPAGE

[cfsqlite web site](https://github.com/bkidwell/cfsqlite)

## SEE ALSO

[SQLite](http://sqlite.org/) web site; [syntax documentation](http://sqlite.org/lang.html).

[sqlitejdbc](http://www.zentus.com/sqlitejdbc/) JDBC driver for Java.

## CONTACT

Brendan Kidwell <[brendan@glump.net](mailto:brendan@glump.net)\>.

Please drop me a line if you find cfsqlite useful (or if you have anything else to say). If you find a bug, please file it in the [issue tracker](https://github.com/bkidwell/cfsqlite/issues/new).
