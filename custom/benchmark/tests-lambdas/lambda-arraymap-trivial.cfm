<cfscript>
	// non-capturing lambda; measures per-call EnvUDF.call machinery
	arrayMap( application.arr1k, (x) => x * 2 );
</cfscript>
