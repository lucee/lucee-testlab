<cfscript>
	// Hot-key write contention: 16 threads, 4 keys.
	// Exercises the LDEV-4413 write-side aliasing path under heavy load —
	// the Storage deque accumulates duplicate entries faster than drain.
	// Master: deque grows, head-first scans get slower.
	// Option 3 (map+queue): map overwrite is O(1), drain queue holds stale refs only.
	cachePut(
		"bench_hot_k_" & randRange( 1, 4 ),
		{ id: randRange( 1, 1000000 ), ts: getTickCount() },
		createTimeSpan( 1, 0, 0, 0 ),
		createTimeSpan( 1, 0, 0, 0 ),
		"redistest"
	);
</cfscript>
