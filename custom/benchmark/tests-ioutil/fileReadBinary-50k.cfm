<cfscript>
	// LDEV-6367 follow-up (option 3 evaluation): just-under-pool toBytes shape.
	// 50 KB is the largest size that still fits inside the BYTE_ARRAY_POOL
	// 64 KB buffer — option 3's pool fast-path triggers here, but BAOS has
	// to double through ~10 intermediate sizes. Last shape where option 3's
	// single-alloc win applies before the pool-overflow fallback kicks in.
	for ( i = 1; i <= 5; i++ ) {
		fileReadBinary( application.ioutilSizedBinaries[ "small-50k.bin" ] );
	}
</cfscript>
