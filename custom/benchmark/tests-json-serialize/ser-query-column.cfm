<cfscript>
	// 50x8 query, column format — column names are emitted ONCE, values in parallel
	// arrays. Fewest escapeJS calls of the three query modes at identical payload.
	// JSONConverter:604 is the key-emitting site.
	d = application.rows;
	n = application.jsLoopMid;
	for ( i = 1; i <= n; i++ ) {
		s = serializeJson( d, "column" );
	}
	if ( len( s ) < 4000 ) throw "query-column failed";
</cfscript>
