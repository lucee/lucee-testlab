<cfscript>
	// pure Lambda allocation cost — no invocation
	fns = [];
	for ( i = 1; i <= 100; i++ ) {
		arrayAppend( fns, (x) => x * 2 );
	}
</cfscript>
