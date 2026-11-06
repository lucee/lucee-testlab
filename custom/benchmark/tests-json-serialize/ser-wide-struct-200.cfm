<cfscript>
	// HEADLINE for presize and the Appendable overload — 200 short ASCII keys with
	// integer values, so nearly every escapeJS call is a ~6-char key needing zero
	// escaping. Maximum calls per serialized byte in the family.
	//
	// Each of those calls today: a char[] copy, a byte[6] StringBuilder, 8 appends
	// into a capacity of 6 (so one guaranteed grow + copy), and a toString copy.
	d = application.wideStruct200;
	n = application.jsLoopSmall;
	for ( i = 1; i <= n; i++ ) {
		s = serializeJson( d );
	}
	if ( len( s ) < 2000 ) throw "wide-struct-200 failed";
</cfscript>
