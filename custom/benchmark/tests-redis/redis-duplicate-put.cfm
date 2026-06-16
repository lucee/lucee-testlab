<cfscript>
	// LDEV-6327 path: two cachePut to the same key, then one cacheGet.
	// Tests stale-wins behaviour under load. With many threads doing this,
	// the deque grows; reads should still return the newer value.
	k = "bench_k_" & randRange( 1, 1000 );
	cachePut(
		k,
		{ v: "v1", ts: getTickCount() },
		createTimeSpan( 1, 0, 0, 0 ),
		createTimeSpan( 1, 0, 0, 0 ),
		"redistest"
	);
	cachePut(
		k,
		{ v: "v2", ts: getTickCount() },
		createTimeSpan( 1, 0, 0, 0 ),
		createTimeSpan( 1, 0, 0, 0 ),
		"redistest"
	);
	cacheGet( k, false, "redistest" );
</cfscript>
