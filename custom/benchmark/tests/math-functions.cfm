<cfscript>
// Math Functions Microbenchmark
// Tests all modified math functions for LDEV-5887 precise math optimization
// Exercises: trig, bitwise, rounding, arithmetic, exponential, random, and base conversion

iterations = 1;
results = [];

// Test data
testValues = [
	0.5,
	1.0,
	-1.5,
	42.7,
	123.456,
	-99.99,
	0.123456789,
	999.999
];

testIntegers = [
	0,
	1,
	-1,
	42,
	123,
	-99,
	255,
	1024
];

for ( iteration = 1; iteration <= iterations; iteration++ ) {

	// Trigonometric functions
	for ( val in testValues ) {
		abs_val = abs( val );
		// Use abs values for asin/acos to avoid NaN
		if ( abs_val <= 1.0 ) {
			acos_result = acos( val );
			asin_result = asin( val );
		}
		atn_result = atn( val );
		cos_result = cos( val );
		sin_result = sin( val );
		tan_result = tan( val );
	}

	// Rounding/Integer functions
	for ( val in testValues ) {
		abs_result = abs( val );
		ceiling_result = ceiling( val );
		fix_result = fix( val );
		floor_result = floor( val );
		int_result = int( val );
		round_result = round( val );
		sgn_result = sgn( val );
	}

	// Arithmetic/Value functions
	for ( val in testValues ) {
		dec_result = decrementValue( val );
		inc_result = incrementValue( val );
	}

	// Min/Max with pairs
	for ( i = 1; i <= arrayLen( testValues ) - 1; i++ ) {
		max_result = max( testValues[i], testValues[i+1] );
		min_result = min( testValues[i], testValues[i+1] );
	}

	// Exponential/Logarithmic functions
	for ( val in testValues ) {
		if ( val > 0 ) {
			log_result = log( val );
			log10_result = log10( val );
			sqr_result = sqr( val );
		}
		exp_result = exp( val );
	}

	// Bitwise operations (integers only)
	for ( i = 1; i <= arrayLen( testIntegers ) - 1; i++ ) {
		val1 = testIntegers[i];
		val2 = testIntegers[i+1];

		bitand_result = bitAnd( val1, val2 );
		bitor_result = bitOr( val1, val2 );
		bitxor_result = bitXor( val1, val2 );
		bitnot_result = bitNot( val1 );
		bitshl_result = bitSHLN( val1, 2 );
		bitshr_result = bitSHRN( val1, 2 );

		// BitMask functions
		if ( val1 >= 0 && val1 < 32 ) {
			bitmask_set = bitMaskSet( 0, 255, val1, 8 );  // number, mask, start, length
			bitmask_read = bitMaskRead( bitmask_set, val1, 8 );  // number, start, length
			bitmask_clear = bitMaskClear( bitmask_set, val1, 8 );  // number, start, length
		}
	}

	// Base conversion
	for ( val in testIntegers ) {
		if ( val >= 0 ) {
			// Convert to base 16 and back
			hex = formatBaseN( val, 16 );
			inputbasen_result = inputBaseN( hex, 16 );
		}
	}

	// Random functions
	rand_result = rand();
	randrange_result = randRange( 1, 100 );
	randomize_result = randomize( 12345 + iteration ); // seed varies per iteration

	// Constant
	pi_result = pi();

	// Store a sample result per iteration to verify work is being done
	arrayAppend( results, {
		iteration: iteration,
		sample_sin: sin( testValues[1] ),
		sample_abs: abs( testValues[3] ),
		sample_rand: rand_result
	} );
}

// Verification: ensure we got expected number of results
if ( arrayLen( results ) != iterations ) {
	throw "Expected #iterations# results, got #arrayLen(results)#";
}

// Verification: check some math properties hold
if ( abs( -5 ) != 5 ) {
	throw "abs(-5) should be 5";
}

if ( ceiling( 4.1 ) != 5 ) {
	throw "ceiling(4.1) should be 5";
}

if ( floor( 4.9 ) != 4 ) {
	throw "floor(4.9) should be 4";
}

</cfscript>
