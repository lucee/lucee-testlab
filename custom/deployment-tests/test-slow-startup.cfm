<cfscript>
// Test LDEV-5478 - Deploy folder timing issue
// This test checks if the slow-startup extension is ready on first request
// If the bug exists, this will fail because the request arrives before onStart() completes

requestTime = now();
requestTimestamp = getTickCount();

try {
	// Try to call the extension's BIF
	isReady = IsSlowStartupReady();
	startupTimestamp = GetSlowStartupTimestamp();

	writeOutput( "Request time: #requestTime#" & chr(10) );
	writeOutput( "Extension ready: #isReady#" & chr(10) );
	writeOutput( "Startup timestamp: #startupTimestamp#" & chr(10) );

	if ( isReady ) {
		writeOutput( "SUCCESS: Extension startup hook completed before first request" & chr(10) );
	}
	else {
		writeOutput( "FAILURE: Extension startup hook NOT completed - LDEV-5478 reproduced!" & chr(10) );
		header statusCode="500";
	}
}
catch ( any e ) {
	writeOutput( "ERROR: Could not call extension function" & chr(10) );
	writeOutput( "Message: #e.message#" & chr(10) );
	if ( structKeyExists( e, "detail" ) && len( e.detail ) ) {
		writeOutput( "Detail: #e.detail#" & chr(10) );
	}
	writeOutput( "This likely means the extension bundle isn't loaded yet - LDEV-5478 reproduced!" & chr(10) );
	header statusCode="500";
}

writeOutput( "Lucee version: #server.lucee.version#" & chr(10) );
</cfscript>
