<cfscript>
	// The realistic version of ser-long-strings-escaped — 20 values, each a JSON
	// document held as a string, so every quote inside gets escaped on the way out.
	// API passthrough and cached-payload shapes do this constantly.
	d = application.embeddedJson;
	n = application.jsLoopMid;
	for ( i = 1; i <= n; i++ ) {
		s = serializeJson( d );
	}
	if ( len( s ) < 1500 ) throw "embedded-json failed";
</cfscript>
