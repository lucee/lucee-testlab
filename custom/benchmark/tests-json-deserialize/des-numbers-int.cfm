<cfscript>
	// HEADLINE for the number-literal path — 1000 small integers, so number() runs
	// 1000 times per parse and each run builds a StringBuilder, a String, a
	// BigDecimal, an LNumber and finally a Double. Nothing else in the document
	// costs anything: no keys, no strings, no escapes.
	//
	// Byte-identical to ser-numbers-array's output, so the two cells are a
	// cross-family pair: parse cost against serialize cost for the same 1000 ints.
	d = application.numbersInt;
	n = application.jdLoopSmall;
	for ( i = 1; i <= n; i++ ) {
		r = deserializeJson( d );
	}
	if ( arrayLen( r ) != 1000 || r[ 1000 ] != 1000 ) throw "numbers-int failed";
</cfscript>
