<cfscript>
	// Diagnostic — prints serialized length of every fixture so cell assertions can be
	// set from fact rather than guesswork. Not a cell (does not match the "ser-" filter).
	fixtures = [ "numbersArray", "wideStruct200", "longStringsClean", "longStringsEscaped", "longStringsLateEscape", "longStringsSparse",
		"embeddedJson", "nonAsciiValues", "apiResponse", "binaryValue", "binaryBig", "big" ];
	for ( f in fixtures ) {
		systemOutput( ljustify( f, 22 ) & " default=" & len( serializeJson( application[ f ] ) ), true );
	}
	systemOutput( ljustify( "nonAsciiValues", 22 ) & " US-ASCII=" & len( serializeJson( application.nonAsciiValues, false, "US-ASCII" ) ), true );
	systemOutput( ljustify( "rows column", 22 ) & " =" & len( serializeJson( application.rows, "column" ) ), true );
	systemOutput( ljustify( "rows struct", 22 ) & " =" & len( serializeJson( application.rows, "struct" ) ), true );
</cfscript>
