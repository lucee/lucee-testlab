<cfscript>
	// CONTROL — the same 1000 digit runs as des-numbers-int, quoted. Identical
	// digits, but every value takes string() and LStringBuilder, so number(),
	// LNumber and BigDecimal are never entered. This cell exists to be UNCHANGED.
	// If a number-literal change moves it, the change reached beyond number().
	//
	// int / quoted is the whole cost of the number path against the string path
	// on the same digits, with 2000 extra quote bytes on the quoted side.
	d = application.numbersQuoted;
	n = application.jdLoopSmall;
	for ( i = 1; i <= n; i++ ) {
		r = deserializeJson( d );
	}
	if ( arrayLen( r ) != 1000 || r[ 1000 ] != "1000" ) throw "numbers-quoted failed";
</cfscript>
