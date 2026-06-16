component {
	this.name = "bench-redis-#hash( getCurrentTemplatePath() )#";
	this.sessionManagement = false;

	this.cache.connections[ "redistest" ] = {
		class: "lucee.extension.io.cache.redis.simple.RedisCache",
		storage: false,
		default: "object",
		custom: {
			"host": "localhost",
			"port": "6379",
			"socketTimeout": "2000",
			"liveTimeout": "3600000",
			"idleTimeout": "60000",
			"timeToLiveSeconds": "0",
			"maxTotal": "40",
			"maxIdle": "24",
			"minIdle": "8"
		}
	};

	// Working-set: 1000 keys, pre-populated for read benches.
	// Random selection in test CFMs draws from this pool.
	this.KEY_POOL_SIZE = 1000;

	function onApplicationStart() {
		// Sanity check: Redis must be up
		try {
			cachePut( "__sanity__", "ok", createTimeSpan( 0, 0, 1, 0 ), createTimeSpan( 0, 0, 1, 0 ), "redistest" );
			cacheRemove( "__sanity__", false, "redistest" );
		} catch ( any e ) {
			throw "Redis not reachable on localhost:6379 — start with `docker compose --profile standalone up -d` in D:\testbeds\redis-extension-test. Cause: #e.message#";
		}

		// Seed the key pool with small structs. Some benches read these; some overwrite.
		systemOutput( "Seeding #this.KEY_POOL_SIZE# keys into Redis...", true );
		var seedStart = getTickCount();
		for ( var i = 1; i <= this.KEY_POOL_SIZE; i++ ) {
			cachePut(
				"bench_k_#i#",
				{ id: i, label: "seed_#i#", payload: repeatString( "x", 100 ) },
				createTimeSpan( 1, 0, 0, 0 ),
				createTimeSpan( 1, 0, 0, 0 ),
				"redistest"
			);
		}
		// Force drain so reads start with a populated Redis
		cacheGetAllIds( "*", "redistest" );
		systemOutput( "Seeded in #getTickCount() - seedStart#ms", true );
	}
}
