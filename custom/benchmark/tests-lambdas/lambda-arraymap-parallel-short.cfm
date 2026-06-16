<cfscript>
	// trivial body, parallel=true — exposes ExecutorService create/teardown cost
	arrayMap( application.arr100, (x) => x * 2, true, 4 );
</cfscript>
