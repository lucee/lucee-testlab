<cfscript>
	// Number-literal corpus — NOT a benchmark cell. The default "des-" filter excludes
	// it; run it with run-verify.bat or directly with script-runner
	// (-Dexecute="tests-json-deserialize/verify-invariance.cfm").
	//
	// Purpose: the bit-identical gate for any change to how the interpreter turns a
	// JSON number literal into a value. Run it against the current build, keep the
	// output, apply the change, run it again, diff. Every line records the three
	// things a caller can observe: the Java type of the value, its CFML string form,
	// and the raw IEEE-754 bits when it is a Double. The bits are the point. Two
	// routes to a double (BigDecimal.doubleValue() against Double.parseDouble()) are
	// only interchangeable if they land on the same 64 bits for every literal the
	// JSON grammar can produce, and toString() hides a 1-ulp difference behind its
	// shortest-repr rounding.
	//
	// Each literal is parsed four ways: bare, as the only array element, as a struct
	// value, and concatenated with an empty string through evaluate(). The literal ref
	// is the same in all four; the first three differ in the container path that pulls
	// getValue() out of it, the last one reads getString() instead.
	//
	// Runs under whatever preciseMath the application has (default off). The precise
	// path is the one a fast-path change leaves alone; set this.preciseMath = true in
	// Application.cfc and re-run if a change claims to touch it.

	cases = [];
	function addCase( name, literal ) {
		arrayAppend( variables.cases, { "name": arguments.name, "literal": arguments.literal } );
	}

	// --- small integers ------------------------------------------------------
	addCase( "zero", "0" );
	addCase( "one", "1" );
	addCase( "int-2digit", "42" );
	addCase( "int-4digit", "1000" );
	addCase( "int-leading-zero", "007" );
	addCase( "neg-zero", "-0" );
	addCase( "neg-one", "-1" );
	addCase( "plus-one", "+1" );

	// --- fractions -----------------------------------------------------------
	addCase( "frac-0.1", "0.1" );
	addCase( "frac-0.2", "0.2" );
	addCase( "frac-0.3", "0.3" );
	addCase( "frac-1.0", "1.0" );
	addCase( "frac-trailing-zero", "1.50" );
	addCase( "frac-leading-dot", ".5" );
	addCase( "frac-neg", "-12345.678" );
	addCase( "frac-classic-sum", "0.30000000000000004" );
	addCase( "frac-round-half", "2.675" );
	addCase( "frac-mixed-9", "123456789.123456789" );
	addCase( "frac-neg-zero", "-0.0" );

	// --- exponents -----------------------------------------------------------
	addCase( "exp-int", "1e3" );
	addCase( "exp-frac", "1.5e3" );
	addCase( "exp-neg", "1e-3" );
	addCase( "exp-plus", "1e+3" );
	addCase( "exp-upper", "1E3" );
	addCase( "exp-neg-mantissa", "-2.5e-7" );

	// --- double edges ---------------------------------------------------------
	// Values where correctly-rounded decimal-to-double conversion is known to be hard.
	addCase( "dbl-max", "1.7976931348623157e308" );
	addCase( "dbl-overflow", "1e309" );
	addCase( "dbl-min-normal", "2.2250738585072014e-308" );
	addCase( "dbl-min-subnormal", "4.9e-324" );
	addCase( "dbl-underflow", "1e-400" );
	addCase( "dbl-php-hang", "2.2250738585072012e-308" );
	addCase( "dbl-1e23", "100000000000000000000000" );
	addCase( "dbl-8.41e21", "8.41e21" );
	addCase( "dbl-2pow53", "9007199254740992" );
	addCase( "dbl-2pow53-plus-1", "9007199254740993" );
	addCase( "dbl-2pow63", "9223372036854775808" );

	// --- digit-count ladder ---------------------------------------------------
	// <=18 digits: BigDecimal keeps the unscaled value in a long (compact).
	// >18: BigInteger. >34: DECIMAL128 rounds at construction, before doubleValue().
	addCase( "digits-18", "999999999999999999" );
	addCase( "digits-19", "1234567890123456789" );
	addCase( "digits-20", "12345678901234567890" );
	addCase( "digits-25", "1234567890123456789012345" );
	addCase( "digits-34", "1234567890123456789012345678901234" );
	addCase( "digits-35", "12345678901234567890123456789012345" );
	addCase( "digits-40", "1234567890123456789012345678901234567890" );
	addCase( "digits-34-frac", "0.1000000000000000055511151231257827" );
	addCase( "digits-40-frac", "0.1000000000000000055511151231257827021182" );
	addCase( "digits-35-round-up", "99999999999999999999999999999999999" );

	// ---------------------------------------------------------------------------

	Dbl = createObject( "java", "java.lang.Double" );
	Lng = createObject( "java", "java.lang.Long" );

	function describe( any v ) {
		var cls = getMetadata( arguments.v ).getName();
		var out = ljustify( listLast( cls, "." ), 11 ) & " str=" & ljustify( toString( arguments.v ), 26 );
		if ( cls == "java.lang.Double" )
			out &= " bits=0x" & ucase( Lng.toHexString( Dbl.doubleToRawLongBits( arguments.v ) ) );
		return out;
	}

	function parseCase( string literal, string shape ) {
		// Deliberate catch-and-record: a characterisation harness, so "case X throws Y"
		// is a result to diff, not an error to propagate.
		try {
			switch ( arguments.shape ) {
				case "bare":
					return describe( deserializeJson( arguments.literal ) );
				case "array":
					return describe( deserializeJson( "[" & arguments.literal & "]" )[ 1 ] );
				case "struct":
					return describe( deserializeJson( '{"n":' & arguments.literal & '}' ).n );
				case "concat":
					// the literal in string context: Concat calls the ref's getString(), a separate
					// output surface from getValue(), reached through the CFML (non-JSON) interpreter
					return describe( evaluate( arguments.literal & " & ''" ) );
			}
		}
		catch ( any e ) {
			return "!! " & e.type & ": " & e.message;
		}
	}

	systemOutput( "", true );
	systemOutput( "=== JSON number-literal corpus — Lucee " & server.lucee.version & " ===", true );
	systemOutput( "cases: " & arrayLen( cases ) & " x 4 shapes, preciseMath=" & ( getApplicationSettings().preciseMath ?: "n/a" ), true );
	systemOutput( "", true );

	allOut = "";
	loop array=[ "bare", "array", "struct", "concat" ] item="shape" {
		systemOutput( "--- shape: " & shape & " ---", true );
		for ( c in cases ) {
			out = parseCase( c.literal, shape );
			allOut &= out;
			systemOutput( ljustify( c.name, 20 ) & " " & ljustify( c.literal, 42 ) & " " & out, true );
		}
		systemOutput( "", true );
	}

	// Whole-corpus fingerprint — one line to compare when the per-case detail is noise.
	systemOutput( "CORPUS FINGERPRINT sha1=" & lcase( hash( allOut, "SHA-1" ) ), true );
	systemOutput( "", true );
</cfscript>
