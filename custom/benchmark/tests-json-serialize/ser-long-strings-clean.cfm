<cfscript>
	// HEADLINE for dropping toCharArray() and for the no-escape fast path — 10 keys,
	// ~4KB of pure ASCII each. Few calls, enormous char count per call, and every
	// value needs zero escaping so a first-index-needing-work scan can bulk-append
	// the whole string instead of 4000 individual append(char) calls.
	d = application.longStringsClean;
	n = application.jsLoopMid;
	for ( i = 1; i <= n; i++ ) {
		s = serializeJson( d );
	}
	if ( len( s ) < 40000 ) throw "long-strings-clean failed";
</cfscript>
