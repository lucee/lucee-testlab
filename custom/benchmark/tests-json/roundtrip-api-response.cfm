<cfscript>
	loop times=#application.innerLoop# {
		r = deserializeJson( application.apiResponse );
		s = serializeJson( r );
	}
	if ( len( s ) < 100 ) throw "roundtrip failed";
</cfscript>
