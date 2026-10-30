<cfscript>
	n = application.shortLoop;
	loop times=#n# {
		r = reMatch( "[0-9]+", "abc def" );
	}
	if ( arrayLen( r ) != 0 ) throw "rematch-short-miss: expected no matches";
</cfscript>
