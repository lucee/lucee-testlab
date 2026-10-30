<cfscript>
	n = application.shortLoop;
	loop times=#n# {
		r = reReplace( "hello-world-2026", "[^a-z0-9-]+", "", "all" );
	}
	if ( r != "hello-world-2026" ) throw "rereplace-short-miss: got [#r#]";
</cfscript>
