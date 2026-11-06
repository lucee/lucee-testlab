<cfscript>
	// A/B PARTNER for ser-long-strings-clean — same key count, same value length,
	// but ~1 char in 10 needs an escape, so the no-escape fast path never fires.
	// clean / escaped IS the cost of the per-character escape branching, measured
	// with payload size held constant.
	d = application.longStringsEscaped;
	n = application.jsLoopMid;
	for ( i = 1; i <= n; i++ ) {
		s = serializeJson( d );
	}
	if ( len( s ) < 40000 ) throw "long-strings-escaped failed";
</cfscript>
