<cfscript>
	// LDEV-6367 follow-up (option 3 evaluation): Preside-shape mixed reads.
	// Approximates the soak workload — mostly small (often empty) HTTP request
	// bodies via cfthread clone, with occasional larger reads. Each cycle:
	//   1 empty  (GET body)
	//   2 tiny   (login form / small JSON)
	//   1 10 KB  (AJAX POST body)
	//   1 1 MB   (big.bin — occasional file/BLOB read)
	fileReadBinary( application.ioutilSizedBinaries[ "empty.bin"     ] );
	fileReadBinary( application.ioutilSizedBinaries[ "tiny.bin"      ] );
	fileReadBinary( application.ioutilSizedBinaries[ "tiny.bin"      ] );
	fileReadBinary( application.ioutilSizedBinaries[ "small-10k.bin" ] );
	fileReadBinary( application.ioutilBigBinary );
</cfscript>
