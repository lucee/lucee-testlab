<cfscript>
	n = application.shortLoop;
	loop times=#n# {
		r = reFind( "[0-9]+", "abc def", 1, false, "all" );
	}
	if ( r != 0 ) throw "refind-all-miss: expected 0";
</cfscript>
