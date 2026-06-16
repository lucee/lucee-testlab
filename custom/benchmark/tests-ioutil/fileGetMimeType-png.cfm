<cfscript>
	// Spec #1 (tika-singleton): single-file, 5 calls per cycle.
	// 5x amplification gives ~500us/cycle vs ~20us harness floor — clean signal,
	// 20x less work than the initial 100x cut.
	for ( i = 1; i <= 5; i++ ) {
		fileGetMimeType( application.ioutilHotFile );
	}
</cfscript>
