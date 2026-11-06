<cfscript>
	// A/B PARTNER for ser-nonascii-utf8 on IDENTICAL data. Forcing US-ASCII makes
	// canEncode() false for everything >= 128, so escapeJS takes the \uXXXX branch
	// instead of appending raw — output stays LATIN1 and neither builder inflates.
	//
	// utf8 / ascii-charset separates the inflation cost from the escape cost. The
	// \uXXXX branch does strictly MORE work per char (a 4-way length test plus
	// Integer.toHexString), so if this cell is nonetheless faster, inflation is the
	// dominant term and the fix belongs in the builder sizing, not the branch.
	//
	// Third positional arg is useSecureJSONPrefixOrCharset — a non-boolean string
	// there is read as a charset (SerializeJSON.java:67).
	d = application.nonAsciiValues;
	n = application.jsLoopMid;
	for ( i = 1; i <= n; i++ ) {
		s = serializeJson( d, false, "US-ASCII" );
	}
	if ( len( s ) < 5000 ) throw "nonascii-ascii-charset failed";
</cfscript>
