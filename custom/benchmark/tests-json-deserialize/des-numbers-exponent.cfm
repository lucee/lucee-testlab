<cfscript>
	// 1000 literals in scientific notation, i.5e3. The exponent branch of number(),
	// then a BigDecimal with a negative scale that doubleValue() has to undo. Real
	// payloads rarely look like this; the cell is here so the branch is covered and
	// a change to it is visible, not because it is expected to matter.
	d = application.numbersExponent;
	n = application.jdLoopSmall;
	for ( i = 1; i <= n; i++ ) {
		r = deserializeJson( d );
	}
	if ( arrayLen( r ) != 1000 || r[ 1 ] != 1500 ) throw "numbers-exponent failed";
</cfscript>
