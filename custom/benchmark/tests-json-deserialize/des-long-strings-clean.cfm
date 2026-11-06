<cfscript>
	// 10 keys, ~4KB of pure ASCII each, byte-identical to ser-long-strings-clean's
	// output. Zero numbers, so the second control for the number-literal change,
	// and the char-count headline for string(): one LStringBuilder.append(char) per
	// char and the backslash branch never taken.
	d = application.longStringsClean;
	n = application.jdLoopMid;
	for ( i = 1; i <= n; i++ ) {
		r = deserializeJson( d );
	}
	if ( structCount( r ) != 10 || len( r.field1 ) < 4000 ) throw "long-strings-clean failed";
</cfscript>
