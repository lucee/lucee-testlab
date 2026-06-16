<cfscript>
	// Sustained write burst on a hot key — no reads.
	// 5 sequential puts to the same key per iteration, 16 threads, 4 keys.
	// Isolates the deque-growth cost on master vs map-overwrite cost on option 3.
	// Also stress-tests the drain thread — does it keep up, or does the queue/deque blow out?
	k = "bench_hot_k_" & randRange( 1, 4 );
	loop times=5 {
		cachePut(
			k,
			{ id: randRange( 1, 1000000 ), ts: getTickCount() },
			createTimeSpan( 1, 0, 0, 0 ),
			createTimeSpan( 1, 0, 0, 0 ),
			"redistest"
		);
	}
</cfscript>
