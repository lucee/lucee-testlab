<cfscript>
	// Same 1000 integer parts as des-numbers-int with a fixed 5-digit fraction, so
	// every literal carries a scale. decimal / int is the fractional branch in
	// number() plus BigDecimal's scaled parse and the scale handling in
	// doubleValue(), for 6 extra chars per literal. This is the shape real
	// payloads' prices, scores and coordinates have.
	d = application.numbersDecimal;
	n = application.jdLoopSmall;
	for ( i = 1; i <= n; i++ ) {
		r = deserializeJson( d );
	}
	if ( arrayLen( r ) != 1000 || r[ 1 ] != 1.14159 ) throw "numbers-decimal failed";
</cfscript>
