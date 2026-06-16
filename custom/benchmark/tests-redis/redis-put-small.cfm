<cfscript>
	// PUT a small struct under a random key in the 1k pool.
	// Exercises serialise + queue + (eventually) drain to Redis.
	cachePut(
		"bench_k_" & randRange( 1, 1000 ),
		{ id: randRange( 1, 1000000 ), ts: getTickCount() },
		createTimeSpan( 1, 0, 0, 0 ),
		createTimeSpan( 1, 0, 0, 0 ),
		"redistest"
	);
</cfscript>
