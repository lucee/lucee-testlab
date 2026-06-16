<cfscript>
	// Read-heavy: 10 gets in a row, random keys from the pool.
	// Simulates a request that loads several cached objects.
	// (Misnamed "redis-mget" previously — doesn't actually use the mget API.)
	loop times=10 {
		cacheGet( "bench_k_" & randRange( 1, 1000 ), false, "redistest" );
	}
</cfscript>
