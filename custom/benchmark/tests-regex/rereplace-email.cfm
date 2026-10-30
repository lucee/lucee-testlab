<cfscript>
	loop times=#application.innerLoop# {
		r = reReplace( application.sampleText, "([a-z0-9._%+-]+)@([a-z0-9.-]+)", "\1@[redacted]", "all" );
	}
	if ( !len( r ) ) throw "rereplace-email: empty result";
</cfscript>
