<cfscript>
	// A/B PARTNER for des-long-strings-clean — same key count, same value length,
	// one char in three is a backslash escape (\", \\, \t, \n), so string() runs its
	// isNext() ladder on every third char. escaped / clean is the cost of the escape
	// branching on the parse side, the mirror of the serialize family's pair.
	d = application.longStringsEscaped;
	n = application.jdLoopMid;
	for ( i = 1; i <= n; i++ ) {
		r = deserializeJson( d );
	}
	if ( structCount( r ) != 10 || len( r.field1 ) < 3900 ) throw "long-strings-escaped failed";
</cfscript>
