<cfscript>
	// Spec #1 (tika-singleton): 8-file rotation, 5 calls per cycle.
	// Matches the standalone microbench rotation pattern at
	// runtime/ioutil/bench/tika-singleton-bench.cfm.
	for ( i = 1; i <= 5; i++ ) {
		fileGetMimeType( application.ioutilFiles[ ( i mod application.ioutilCount ) + 1 ] );
	}
</cfscript>
