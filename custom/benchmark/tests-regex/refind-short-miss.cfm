<cfscript>
	n = application.shortLoop;
	loop times=#n# {
		r = reFind( "[0-9]+", "abc def" );
	}
	if ( r != 0 ) throw "refind-short-miss: expected 0, got #r#";
</cfscript>
