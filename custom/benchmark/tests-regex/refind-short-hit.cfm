<cfscript>
	n = application.shortLoop;
	loop times=#n# {
		r = reFind( "[0-9]+", "abc 123" );
	}
	if ( r != 5 ) throw "refind-short-hit: expected 5, got #r#";
</cfscript>
