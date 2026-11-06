<cfscript>
	// A/B PARTNER for des-numbers-int — the same 1000 integers, negated. The minus
	// is read by negateMinusOp(), not number(): it wraps the LNumber in a Negate ref
	// whose getValue() resolves preciseMath again and does a second
	// Caster.toDoubleValue + Double.valueOf on top of the literal's own conversion.
	// negative / int is the cost of that wrapper at identical digit count.
	d = application.numbersNegative;
	n = application.jdLoopSmall;
	for ( i = 1; i <= n; i++ ) {
		r = deserializeJson( d );
	}
	if ( arrayLen( r ) != 1000 || r[ 1000 ] != -1000 ) throw "numbers-negative failed";
</cfscript>
