<cfscript>
	// LDEV-4413 read-side path: put then immediate get of the SAME key.
	// Near cache should be hot; PR #16's copy() runs every read.
	k = "bench_k_" & randRange( 1, 1000 );
	cachePut(
		k,
		{ id: randRange( 1, 1000000 ), ts: getTickCount() },
		createTimeSpan( 1, 0, 0, 0 ),
		createTimeSpan( 1, 0, 0, 0 ),
		"redistest"
	);
	cacheGet( k, false, "redistest" );
</cfscript>
