<cfscript>
	// LDEV-6367 follow-up (option 3 evaluation): tiny-stream toBytes shape.
	// Models login-form-shape HTTP request bodies in the Preside soak.
	// At 100 bytes the BAOS doubling pattern wastes 3 intermediate allocs
	// (32->64->128) for a 100-byte payload, and readAllBytes still allocates
	// a 16 KB initial chunk. Option 3 (pool-aware) should single-alloc 100 B.
	for ( i = 1; i <= 5; i++ ) {
		fileReadBinary( application.ioutilSizedBinaries[ "tiny.bin" ] );
	}
</cfscript>
