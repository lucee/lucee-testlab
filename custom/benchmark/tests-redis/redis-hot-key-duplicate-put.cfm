<cfscript>
	// LDEV-6327 stale-wins path under hot-key contention.
	// 16 threads on 4 keys: each thread puts v1 then v2 to the same key, then reads.
	// Master: get does head-first deque scan, frequently returns the stale v1
	//         (or a v2 from a different thread overwritten in the meantime).
	// Option 3: map overwrite ensures the get returns the latest write deterministically.
	k = "bench_hot_k_" & randRange( 1, 4 );
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
