<cfscript>
	// CONTROL — 1000 integers, so serializeJSON never calls escapeJS once.
	// This cell exists to be UNCHANGED. Any escapeJS work that moves it has
	// touched the number/array walk, not the string path.
	d = application.numbersArray;
	n = application.jsLoopSmall;
	for ( i = 1; i <= n; i++ ) {
		s = serializeJson( d );
	}
	if ( len( s ) < 3000 ) throw "numbers-array failed";
</cfscript>
