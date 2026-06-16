<cfscript>
	// LDEV-6367 follow-up (option 3 evaluation): empty-stream toBytes shape.
	// Models the dominant Preside soak path — HttpServletRequestDummy.clone
	// reading empty GET request bodies (94% of toBytes-attributed allocations
	// in the 2026-05-29 soak). Tests the edge case where readAllBytes still
	// allocates a 16 KB initial chunk vs option 3 returning an empty byte[]
	// after a single EOF read.
	for ( i = 1; i <= 5; i++ ) {
		fileReadBinary( application.ioutilSizedBinaries[ "empty.bin" ] );
	}
</cfscript>
