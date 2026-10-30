<cfscript>
	// POSIX classes, Wheels humanize() style; compat translates them to Unicode properties,
	// java reads [[:upper:]] as a nested class, so its result differs
	loop times=#application.innerLoop# {
		r = reMatch( "[[:upper:]][[:lower:]]+", application.sampleText );
	}
	if ( !arrayLen( r ) ) throw "rematch-posix: no matches";
</cfscript>
