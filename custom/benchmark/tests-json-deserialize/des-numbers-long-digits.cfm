<cfscript>
	// 1000 25-digit integers. Above 18 significant digits BigDecimal cannot keep the
	// unscaled value in a long and carries a BigInteger, so the parse and the
	// doubleValue() conversion both leave the compact fast path JDK 21+ gives small
	// values. Below DECIMAL128's 34 digits, so nothing is rounded at construction.
	// Double.parseDouble has no cliff at 18 digits, so this is where the two routes
	// differ most in work while still producing the same double. Snowflake ids and
	// 64-bit hashes serialized as numbers are the real-world version.
	d = application.numbersLongDigits;
	n = application.jdLoopSmall;
	for ( i = 1; i <= n; i++ ) {
		r = deserializeJson( d );
	}
	if ( arrayLen( r ) != 1000 || r[ 1 ] < 1e24 ) throw "numbers-long-digits failed";
</cfscript>
