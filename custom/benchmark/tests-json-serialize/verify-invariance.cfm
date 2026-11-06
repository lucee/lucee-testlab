<cfscript>
	// escapeJS value corpus — NOT a benchmark cell. The default "ser-" filter excludes
	// it; run it directly with script-runner (-Dexecute="tests-json-serialize/verify-invariance.cfm").
	//
	// Purpose: the byte-identical gate for any change to StringUtil.escapeJS. Run it
	// against the current build, keep the output, apply the change, run it again, diff.
	// A single differing line is a breaking change to a serialization surface — apps
	// hash, store, diff and cross-engine-compare this output.
	//
	// Cases marked [SURROGATE] are the ones that actually break. escapeJS iterates
	// char-by-char, so a surrogate pair is two independent iterations, each >= 128 and
	// each escaped on its own. Any rewrite that starts reasoning in code points will
	// change these lines. Stay char-based.
	//
	// Every case runs under both charsets, because the encoder decides the whole
	// non-ASCII branch: UTF-8 canEncode() everything so chars are appended raw
	// (and inflate the builder), US-ASCII rejects them so they take \uXXXX.

	cases = [];
	function addCase( name, value ) {
		arrayAppend( variables.cases, { "name": arguments.name, "value": arguments.value } );
	}

	// --- baseline shapes -------------------------------------------------------
	addCase( "empty", "" );
	addCase( "ascii-plain", "hello world" );
	// byte[] never reaches escapeJS, it is base64 in JSONConverter and wrapped in quotes by a concat; pinned so that site can change
	addCase( "binary", charsetDecode( "hello world", "utf-8" ) );

	// every printable ASCII char in one string
	printable = "";
	for ( i = 32; i <= 126; i++ ) printable &= chr( i );
	addCase( "ascii-32-126", printable );

	// --- the explicit switch cases, isolated then adjacent --------------------
	addCase( "backslash", "a\b" );
	addCase( "backslash-double", "a\\b" );
	addCase( "quote-double", 'a"b' );
	addCase( "quote-single", "a'b" );
	addCase( "quote-both-adjacent", 'a"' & "'b" );
	addCase( "newline", "a" & chr( 10 ) & "b" );
	addCase( "carriage-return", "a" & chr( 13 ) & "b" );
	addCase( "crlf", "a" & chr( 13 ) & chr( 10 ) & "b" );
	addCase( "formfeed", "a" & chr( 12 ) & "b" );
	addCase( "backspace", "a" & chr( 8 ) & "b" );
	addCase( "tab", "a" & chr( 9 ) & "b" );
	addCase( "all-escapes-adjacent", "\" & chr( 10 ) & chr( 13 ) & chr( 12 ) & chr( 8 ) & chr( 9 ) & '"' & "'" );

	// --- the </script lookahead, which is the one stateful branch -------------
	addCase( "script-close-mid", "a</script>b" );
	addCase( "script-close-with-space", "a</script >b" );
	addCase( "script-close-start", "</script>" );
	addCase( "script-close-at-end", "a</script" );
	addCase( "script-truncated-1", "a</scrip" );
	addCase( "script-truncated-2", "a</s" );
	addCase( "script-truncated-slash-only", "a</" );
	addCase( "slash-plain", "a/b" );
	addCase( "slash-after-lt-not-script", "a</b>c" );
	addCase( "slash-double", "http://example.com/path" );
	addCase( "lt-slash-uppercase", "a</SCRIPT>b" );

	// --- ISO controls, the isISOControl() default branch ----------------------
	addCase( "ctrl-0x00", "a" & chr( 0 ) & "b" );
	addCase( "ctrl-0x01", "a" & chr( 1 ) & "b" );
	addCase( "ctrl-0x1F", "a" & chr( 31 ) & "b" );
	addCase( "ctrl-0x7F", "a" & chr( 127 ) & "b" );
	addCase( "ctrl-0x80", "a" & chr( 128 ) & "b" );
	addCase( "ctrl-0x9F", "a" & chr( 159 ) & "b" );
	addCase( "boundary-0xA0", "a" & chr( 160 ) & "b" );

	// --- the \u000 / \u00 / \u0 / \u length ladder ---------------------------
	// Four branches picked by magnitude; one case each side of every boundary.
	addCase( "hex-ladder-0x0F", "a" & chr( 15 ) & "b" );
	addCase( "hex-ladder-0x10", "a" & chr( 16 ) & "b" );
	addCase( "hex-ladder-0xFF", "a" & chr( 255 ) & "b" );
	addCase( "hex-ladder-0x100", "a" & chr( 256 ) & "b" );
	addCase( "hex-ladder-0xFFF", "a" & chr( 4095 ) & "b" );
	addCase( "hex-ladder-0x1000", "a" & chr( 4096 ) & "b" );

	// --- non-ASCII BMP -------------------------------------------------------
	addCase( "latin1-accents", chr( 233 ) & chr( 224 ) & chr( 246 ) & chr( 241 ) & chr( 229 ) );
	addCase( "cjk", chr( 20013 ) & chr( 25991 ) );
	addCase( "hiragana", chr( 12354 ) & chr( 12356 ) );
	addCase( "cyrillic", chr( 1055 ) & chr( 1088 ) );
	addCase( "mixed-ascii-nonascii", "start " & chr( 233 ) & " mid " & chr( 20013 ) & " end" );
	addCase( "nonascii-first-char", chr( 233 ) & " trailing ascii" );
	addCase( "nonascii-last-char", "leading ascii " & chr( 233 ) );

	// --- [SURROGATE] the cases that break on a code-point rewrite -------------
	addCase( "surrogate-pair-emoji", chr( 55357 ) & chr( 56832 ) );
	addCase( "surrogate-pair-in-context", "a" & chr( 55357 ) & chr( 56832 ) & "b" );
	addCase( "surrogate-high-unpaired", "a" & chr( 55357 ) & "b" );
	addCase( "surrogate-low-unpaired", "a" & chr( 56832 ) & "b" );
	addCase( "surrogate-reversed", "a" & chr( 56832 ) & chr( 55357 ) & "b" );

	// --- builder boundary ----------------------------------------------------
	// escapeJS seeds StringBuilder at exactly str.length() then appends length+2,
	// so a no-escape string always overflows by two. These pin the sizes either
	// side of the internal doubling so a presize change is proven not to alter output.
	loop list="0,1,2,15,16,17,31,32,33" item="sz" {
		addCase( "boundary-len-" & sz, repeatString( "x", int( sz ) ) );
	}

	// --- key escaping, not just values ---------------------------------------
	// Struct keys go through the same escapeJS. Keys are also case-mangled unless
	// preserveCase is on, which is orthogonal but shows up in this output.
	// Ordered, not a plain struct: a hash-ordered map would make the corpus depend on
	// key iteration order, and a reorder would show up as a diff that has nothing to
	// do with escaping. The gate has to be stable for reasons unrelated to escapeJS.
	keyCases = structNew( "ordered" );
	keyCases[ 'key"quote' ] = 1;
	keyCases[ "key\backslash" ] = 2;
	keyCases[ "key" & chr( 9 ) & "tab" ] = 3;
	keyCases[ "key" & chr( 233 ) & "accent" ] = 4;

	// ---------------------------------------------------------------------------

	function serializeCase( any value, string charset ) {
		// Deliberate catch-and-record: this is a characterisation harness, so "case X
		// throws Y" is a result to diff, not an error to propagate. Dying on case 3 of
		// 60 would hide the other 57.
		try {
			if ( len( arguments.charset ) )
				return serializeJson( arguments.value, false, arguments.charset );
			return serializeJson( arguments.value );
		}
		catch ( any e ) {
			return "!! " & e.type & ": " & e.message;
		}
	}

	function printCase( string name, string charset, string out ) {
		// Renders every char >= 127 and every control as <U+XXXX> ITSELF rather than
		// trusting the console. script-runner's stdout is written in the platform
		// codepage, which turned every non-ASCII char into "?" on the first run — two
		// different accents rendered identically, which would silently hide a real
		// diff in exactly the cases this corpus exists to protect.
		//
		// The SHA-1 is always over the RAW output, never the safe rendering, so the
		// fingerprint reflects true bytes.
		var safe = "";
		var n = len( arguments.out );
		var code = 0;
		var ch = "";
		var i = 0;
		for ( i = 1; i <= n; i++ ) {
			ch = mid( arguments.out, i, 1 );
			code = asc( ch );
			if ( code >= 127 || code < 32 )
				safe &= "<U+" & ucase( right( "000" & formatBaseN( code, 16 ), 4 ) ) & ">";
			else
				safe &= ch;
		}
		var detail = n <= 96
			? safe
			: "len=" & n & " sha1=" & lcase( hash( arguments.out, "SHA-1" ) );
		systemOutput(
			ljustify( arguments.name, 30 ) & " " & ljustify( arguments.charset, 9 ) & " " & detail,
			true
		);
	}

	systemOutput( "", true );
	systemOutput( "=== escapeJS value corpus — Lucee " & server.lucee.version & " ===", true );
	systemOutput( "cases: " & arrayLen( cases ) & " x 2 charsets", true );
	systemOutput( "", true );

	loop list="default,US-ASCII" item="cs" {
		charset = ( cs == "default" ) ? "" : cs;
		systemOutput( "--- charset: " & cs & " ---", true );
		for ( c in cases ) {
			printCase( c.name, cs, serializeCase( [ c.value ], charset ) );
		}
		printCase( "struct-keys", cs, serializeCase( keyCases, charset ) );
		systemOutput( "", true );
	}

	// Whole-corpus fingerprint — one line to compare when the per-case detail is noise.
	allOut = "";
	loop list="default,US-ASCII" item="cs" {
		charset = ( cs == "default" ) ? "" : cs;
		for ( c in cases ) allOut &= serializeCase( [ c.value ], charset );
		allOut &= serializeCase( keyCases, charset );
	}
	systemOutput( "CORPUS FINGERPRINT sha1=" & lcase( hash( allOut, "SHA-1" ) ), true );
	systemOutput( "", true );
</cfscript>
