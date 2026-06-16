<cfscript>
	// LDEV-6367 follow-up (option 3 evaluation): mid-small toBytes shape.
	// Models JSON API request body sizes typical in Preside admin AJAX flow.
	// 10 KB sits comfortably inside the 64 KB pool buffer — option 3 should
	// single-alloc, baseline BAOS doubles ~8 times.
	for ( i = 1; i <= 5; i++ ) {
		fileReadBinary( application.ioutilSizedBinaries[ "small-10k.bin" ] );
	}
</cfscript>
