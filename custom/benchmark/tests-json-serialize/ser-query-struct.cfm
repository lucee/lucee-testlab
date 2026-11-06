<cfscript>
	// A/B PARTNER for ser-query-column — same query, struct format, so every column
	// name is escaped once PER ROW at JSONConverter:559: 8 cols x 50 rows = 400
	// escapeJS key calls, against column format's 16 (8 for the COLUMNS list at :604
	// plus 8 for the DATA keys at :636). Same data, 25x the key-call count.
	//
	// This is the sharpest call-count lever in the family, and the one that maps
	// directly onto what a remote CFC returning a query actually costs. Note the
	// smoke run did NOT show a gap here — see the README's open question.
	d = application.rows;
	n = application.jsLoopMid;
	for ( i = 1; i <= n; i++ ) {
		s = serializeJson( d, "struct" );
	}
	if ( len( s ) < 5000 ) throw "query-struct failed";
</cfscript>
