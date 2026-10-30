<cfscript>
	n = application.shortLoop;
	loop times=#n# {
		r = reMatch( "[0-9]+", "abc 123" );
	}
	if ( arrayLen( r ) != 1 ) throw "rematch-short-hit: expected 1 match";
</cfscript>
