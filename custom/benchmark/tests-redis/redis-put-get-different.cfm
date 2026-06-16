<cfscript>
	// Put one key, get another. Near cache is cold for the GET path.
	// Most reads will hit Redis (after doJoin or via direct fetch).
	putK = "bench_k_" & randRange( 1, 1000 );
	getK = "bench_k_" & randRange( 1, 1000 );
	cachePut(
		putK,
		{ id: randRange( 1, 1000000 ) },
		createTimeSpan( 1, 0, 0, 0 ),
		createTimeSpan( 1, 0, 0, 0 ),
		"redistest"
	);
	cacheGet( getK, false, "redistest" );
</cfscript>
