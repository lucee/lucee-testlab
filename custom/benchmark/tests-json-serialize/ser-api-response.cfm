<cfscript>
	// Realistic mixed payload. Same fixture shape as tests-json/deserialize-api-response,
	// held as the live CFML object, so the two families can be read as a pair on one
	// payload: parse cost vs serialize cost for the same document.
	d = application.apiResponse;
	n = application.jsLoopMid;
	for ( i = 1; i <= n; i++ ) {
		s = serializeJson( d );
	}
	if ( len( s ) < 800 ) throw "api-response failed";
</cfscript>
