<cfscript>
	// Realistic mixed ~830-byte payload, byte-identical to ser-api-response's output
	// and to tests-json/deserialize-api-response's fixture. The cross-family pair the
	// serialize README's open question asked for, valid only when the loop counts are
	// matched for the run (JD_LOOP_MID=10 against jsLoopMid's 10).
	d = application.apiResponse;
	n = application.jdLoopMid;
	for ( i = 1; i <= n; i++ ) {
		r = deserializeJson( d );
	}
	if ( arrayLen( r.data ) != 5 || r.count != 5 ) throw "api-response failed";
</cfscript>
