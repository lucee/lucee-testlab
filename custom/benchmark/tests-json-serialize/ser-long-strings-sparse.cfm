<cfscript>
	// REALISTIC DENSITY — same 10 keys and ~4KB values as ser-long-strings-clean, with
	// a quoted word every 50 chars, which is what prose in a real payload looks like.
	// Sits between clean (no escapes) and escaped (one in three). A design that
	// bulk-appends the runs between escapes is judged on this cell, not the dense one.
	d = application.longStringsSparse;
	n = application.jsLoopMid;
	for ( i = 1; i <= n; i++ ) {
		s = serializeJson( d );
	}
	if ( len( s ) < 40000 ) throw "long-strings-sparse failed";
</cfscript>
