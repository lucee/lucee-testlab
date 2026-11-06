<cfscript>
	// WORST CASE for a whole-string clean scan — same 10 keys and ~4KB values as
	// ser-long-strings-clean, but each value ends in one quote. The first char needing
	// work is the last char, so the scan runs the full length for nothing and the
	// per-char pass then runs the full length again. late / clean is the scan's cost.
	d = application.longStringsLateEscape;
	n = application.jsLoopMid;
	for ( i = 1; i <= n; i++ ) {
		s = serializeJson( d );
	}
	if ( len( s ) < 40000 ) throw "long-strings-late-escape failed";
</cfscript>
