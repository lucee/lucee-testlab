<cfscript>
	// PUT a larger struct (100 entries x ~100 bytes each).
	// Exercises BSON serialise cost — relevant to PR #16's read-side deserialise
	// (every near-cache hit pays this cost post-fix).
	big = {};
	for ( i = 1; i <= 100; i++ ) {
		big[ "field_#i#" ] = repeatString( "x", 100 );
	}
	cachePut(
		"bench_large_" & randRange( 1, 100 ),
		big,
		createTimeSpan( 1, 0, 0, 0 ),
		createTimeSpan( 1, 0, 0, 0 ),
		"redistest"
	);
</cfscript>
