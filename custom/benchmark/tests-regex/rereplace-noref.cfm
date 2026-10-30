<cfscript>
	loop times=#application.innerLoop# {
		r = reReplace( application.sampleText, "\[[a-z/]+\]", "", "all" );
	}
	if ( !len( r ) ) throw "rereplace-noref: empty result";
</cfscript>
