<cfscript>
	// GET a random key from the 1k pool.
	// Mix of near-cache hits (if a writer recently touched the key)
	// and Redis fetches (cold near cache).
	cacheGet( "bench_k_" & randRange( 1, 1000 ), false, "redistest" );
</cfscript>
