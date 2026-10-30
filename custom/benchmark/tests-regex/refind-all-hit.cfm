<cfscript>
	n = application.shortLoop;
	loop times=#n# {
		r = reFind( "[0-9]+", "abc 123", 1, false, "all" );
	}
	if ( !isArray( r ) || arrayLen( r ) != 1 ) throw "refind-all-hit: expected 1 match";
</cfscript>
