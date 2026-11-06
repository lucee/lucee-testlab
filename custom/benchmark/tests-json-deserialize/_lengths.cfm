<cfscript>
	// Diagnostic — prints the byte length and top-level element count of every fixture
	// so cell assertions are set from fact. Not a cell (does not match the "des-" filter).
	fixtures = [ "numbersInt", "numbersQuoted", "numbersNegative", "numbersDecimal", "numbersLongDigits", "numbersExponent",
		"wideStruct200", "longStringsClean", "longStringsEscaped", "apiResponse", "big" ];
	for ( f in fixtures ) {
		s = application[ f ];
		r = deserializeJson( s );
		count = isArray( r ) ? arrayLen( r ) : structCount( r );
		systemOutput( ljustify( f, 20 ) & " bytes=" & ljustify( len( s ), 8 ) & " elements=" & count, true );
	}
</cfscript>
