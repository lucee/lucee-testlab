component {

	this.name = "bench-regex";
	this.sessionManagement = false;
	// engine is the server default, set it with -Dlucee.regex.type / LUCEE_REGEX_TYPE (java, perl, compat)

	function onApplicationStart() {
		application.innerLoop = 10;
		// short-input cells: enough calls per request that regex, not request overhead, dominates
		application.shortLoop = 100;
		application.sampleText = fileRead( expandPath( "res/sample.txt" ) );

		systemOutput(
			"regex bench seeded — engine=[#(getApplicationSettings().regex.type ?: 'perl')#]"
			& "  text=#len( application.sampleText )# chars"
			, true
		);
	}

}
