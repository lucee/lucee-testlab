<cfscript>
	// THE INFLATION PATH. Default web charset is UTF-8, so the JSONConverter holds a
	// UTF-8 CharsetEncoder and canEncode() is true for every non-ASCII char here.
	// escapeJS therefore appends them RAW, and its LATIN1-seeded local StringBuilder
	// inflates to UTF16 on the first one — then the escaped result inflates the outer
	// JSONConverter builder in turn.
	//
	// This is the path compact-string-inflation-hotspots.md measured at 301 small +
	// ~96 giant events in the test-suite JFR and explicitly could NOT see in the
	// preside or wheels soaks, because that data is ASCII.
	d = application.nonAsciiValues;
	n = application.jsLoopMid;
	for ( i = 1; i <= n; i++ ) {
		s = serializeJson( d );
	}
	if ( len( s ) < 5000 ) throw "nonascii-utf8 failed";
</cfscript>
