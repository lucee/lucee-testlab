<cfscript>
	// lazy .*? across lines, Preside <!---(.*?)---> style; perl and compat let . match \n,
	// java doesn't, so its result differs
	loop times=#application.innerLoop# {
		r = reReplace( application.sampleText, "\[/h\](.*?)\[h\]", "[/h][h]", "all" );
	}
	if ( !len( r ) ) throw "rereplace-dotall: empty result";
</cfscript>
