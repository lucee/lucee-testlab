<cfscript>
	// \b at every start position; compat translates \b to a lookaround pair on [\p{L}\p{Nd}_],
	// java's \b is ASCII
	loop times=#application.innerLoop# {
		r = reFind( "\bund\b", application.sampleText, 1, true, "all" );
	}
	if ( !arrayLen( r ) ) throw "refind-boundary: no matches";
</cfscript>
