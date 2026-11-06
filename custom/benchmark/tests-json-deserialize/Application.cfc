component {

	this.name = "bench-json-deserialize";
	this.sessionManagement = false;

	function onApplicationStart() {

		// ---------------------------------------------------------------------------
		// Per-cycle inner loop counts. Same two-tier shape as tests-json-serialize but
		// lower defaults (20 / 5 against 50 / 10), because parsing is ~2x the cost of
		// serializing the same bytes and 50 blew the per-cycle band. For a matched
		// des-/ser- pair set JD_LOOP_SMALL=50 JD_LOOP_MID=10 (or the JS_ side down).
		// Nothing here contends on a shared monitor:
		// every deserializeJSON builds a fresh JSONExpressionInterpreter, so this is a
		// per-call CPU and allocation question. Retune both in the opposite direction
		// to BENCHMARK_CYCLES to hold total work constant.
		// ---------------------------------------------------------------------------
		application.jdLoopSmall = int( server.system.environment.JD_LOOP_SMALL ?: 20 );
		application.jdLoopMid = int( server.system.environment.JD_LOOP_MID ?: 5 );

		// ---------------------------------------------------------------------------
		// Number-literal axis. Every JSON number is read by
		// CFMLExpressionInterpreter.number() into an LNumber, which always builds a
		// BigDecimal under MathContext.DECIMAL128 and converts to Double at getValue()
		// when precise math is off (the default). Five allocations and a decimal parse
		// per literal to land where Double.parseDouble lands in one. The cells below
		// hold the count at 1000 literals per document and vary what the literal
		// looks like, so each step of that detour can be separated.
		// ---------------------------------------------------------------------------

		// --- headline: 1000 small integers -------------------------------------------
		// Byte-identical to what ser-numbers-array emits, so des-numbers-int and
		// ser-numbers-array are a cross-family pair on one payload.
		var nums = [];
		for ( var i = 1; i <= 1000; i++ ) arrayAppend( nums, i );
		application.numbersInt = serializeJson( nums );

		// --- control: the same digits, quoted -----------------------------------------
		// Identical digit runs, but every value goes through string() and
		// LStringBuilder instead of number(), so LNumber and BigDecimal are never
		// touched. Built by hand so nothing can decide the strings look numeric.
		var quoted = '["1"';
		for ( var i = 2; i <= 1000; i++ ) quoted &= ',"' & i & '"';
		application.numbersQuoted = quoted & "]";

		// --- the same integers, negated ----------------------------------------------
		// A leading minus is not part of number(): negateMinusOp() wraps the literal
		// in a Negate ref, which re-resolves preciseMath and does its own
		// Caster.toDoubleValue + Double.valueOf on top of the literal's.
		var negs = [];
		for ( var i = 1; i <= 1000; i++ ) arrayAppend( negs, -i );
		application.numbersNegative = serializeJson( negs );

		// --- the same integer parts with a fixed 5-digit fraction --------------------
		// Every literal carries a scale, so BigDecimal takes the scaled parse and
		// doubleValue() has a scale to deal with. Hand-built so the fraction is the
		// same width on every value.
		var dec = "[1.14159";
		for ( var i = 2; i <= 1000; i++ ) dec &= "," & i & ".14159";
		application.numbersDecimal = dec & "]";

		// --- 25-digit integers -------------------------------------------------------
		// Above 18 significant digits BigDecimal cannot hold the unscaled value in a
		// long and carries a BigInteger, so both the parse and doubleValue() leave the
		// compact fast path JDK 21+ gives small values. Below DECIMAL128's 34 digits,
		// so no rounding at construction. Double.parseDouble has no such cliff.
		var longd = "[1234567890123456789000001";
		for ( var i = 2; i <= 1000; i++ ) longd &= ",12345678901234567890" & numberFormat( i, "00000" );
		application.numbersLongDigits = longd & "]";

		// --- scientific notation -----------------------------------------------------
		// i.5e3. The exponent branch of number(); BigDecimal ends up with a negative
		// scale that doubleValue() has to undo. Coverage for the branch, not a shape
		// real payloads have.
		var exp = "[1.5e3";
		for ( var i = 2; i <= 1000; i++ ) exp &= "," & i & ".5e3";
		application.numbersExponent = exp & "]";

		// ---------------------------------------------------------------------------
		// Mirrors of the serialize family's fixtures, serialized at seed time so the
		// des- cell parses exactly the bytes the ser- cell produces.
		// ---------------------------------------------------------------------------

		// --- 200 short keys, integer values ------------------------------------------
		// Half the tokens are keys, half are number literals: the realistic mix a
		// number-literal change lands on.
		var wide = {};
		for ( var i = 1; i <= 200; i++ ) wide[ "key" & i ] = i;
		application.wideStruct200 = serializeJson( wide );

		// --- 10 keys, ~4KB pure-ASCII values, zero escapes, zero numbers ------------
		var clean = {};
		for ( var i = 1; i <= 10; i++ ) {
			clean[ "field" & i ] = repeatString( "lorem ipsum dolor sit amet consectetur ", 105 );
		}
		application.longStringsClean = serializeJson( clean );

		// --- same shape and size, one char in three is a backslash escape ------------
		// 14-char unit, 5 escapes (\", \", \, \t, \n) so string()'s isNext() ladder
		// runs on every third char.
		var dirty = {};
		var unit = 'say "hi" a\b' & chr( 9 ) & "c" & chr( 10 );
		for ( var i = 1; i <= 10; i++ ) {
			dirty[ "field" & i ] = repeatString( unit, 285 );
		}
		application.longStringsEscaped = serializeJson( dirty );

		// --- realistic mixed payload, ~830 bytes ------------------------------------
		// Same document as ser-api-response and tests-json/deserialize-api-response.
		var api = {
			"status": "ok",
			"timestamp": "2026-06-10T23:00:00Z",
			"count": 5,
			"data": []
		};
		for ( var i = 1; i <= 5; i++ ) {
			arrayAppend( api.data, {
				"id": i,
				"name": "User #i#",
				"email": "user#i#@example.com",
				"age": 25 + i,
				"active": ( i mod 2 ) == 0,
				"tags": [ "tag-a", "tag-b", "tag-c" ],
				"meta": { "created": "2026-01-01", "score": i * 1.5 }
			} );
		}
		application.apiResponse = serializeJson( api );

		// --- sustained: ~41KB, 500 records ------------------------------------------
		// Same document as ser-big and tests-json/deserialize-big. 1000 numbers, 1000
		// strings, 2500 keys, 500 booleans per parse.
		var bigArr = [];
		for ( var i = 1; i <= 500; i++ ) {
			arrayAppend( bigArr, {
				"id": i,
				"name": "Record #i#",
				"value": i * 3.14159,
				"active": ( i mod 3 ) == 0,
				"category": [ "cat-a", "cat-b" ][ ( i mod 2 ) + 1 ]
			} );
		}
		application.big = serializeJson( bigArr );

		systemOutput(
			"JSON deserialize bench seeded"
			& " — numbers-int: " & numberFormat( len( application.numbersInt ) ) & " bytes"
			& ", quoted: " & numberFormat( len( application.numbersQuoted ) )
			& ", long-digits: " & numberFormat( len( application.numbersLongDigits ) )
			& ", clean: " & numberFormat( len( application.longStringsClean ) )
			& ", escaped: " & numberFormat( len( application.longStringsEscaped ) )
			& ", big: " & numberFormat( len( application.big ) / 1024, "0.0" ) & "KB"
			, true
		);
	}

}
