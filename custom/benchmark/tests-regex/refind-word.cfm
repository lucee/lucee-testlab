<cfscript>
	// \w before a literal, retried at every start position; compat translates \w to [\p{L}\p{Nd}_],
	// java's \w is ASCII, so it splits on the umlauts and its result differs
	loop times=#application.innerLoop# {
		r = reFind( "\w+@", application.sampleText, 1, true, "all" );
	}
	if ( !arrayLen( r ) ) throw "refind-word: no matches";
</cfscript>
