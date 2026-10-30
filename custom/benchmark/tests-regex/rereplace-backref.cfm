<cfscript>
	loop times=#application.innerLoop# {
		r = reReplace( application.sampleText, "\[([a-z]+)\]", "<\1>", "all" );
	}
	if ( !len( r ) ) throw "rereplace-backref: empty result";
</cfscript>
