<cfscript>
	// 64KB byte[] — matches LDEV-6052 benchmark payload size. Two costs stack here:
	// the hand-rolled Base64Encoder allocating a char[4] per 3 input bytes (~21,800
	// of them per call) into an un-presized StringBuilder, and JSONConverter:800
	// concatenating the whole ~87KB base64 result a second time just to add quotes.
	//
	// escapeJS is NOT on this path — binary goes straight to Base64Coder.encode.
	// So this cell should not move on an escapeJS change, and should move a lot on
	// LDEV-6052.
	d = application.binaryValue;
	n = application.jsLoopMid;
	for ( i = 1; i <= n; i++ ) {
		s = serializeJson( d );
	}
	if ( len( s ) < 80000 ) throw "binary failed";
</cfscript>
