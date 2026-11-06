<cfscript>
	// 4MB byte[] -> ~5.6MB base64 string. Isolates the whole-payload copies on the
	// binary path at a size where each one is a G1 humongous allocation. One call per
	// cycle; run it filtered with a low cycle count, never in the family run.
	// escapeJS is NOT on this path.
	s = serializeJson( application.binaryBig );
	if ( len( s ) < 5000000 ) throw "binary-big failed";
</cfscript>
