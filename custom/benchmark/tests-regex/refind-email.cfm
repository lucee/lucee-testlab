<cfscript>
	loop times=#application.innerLoop# {
		r = reFindNoCase( "[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}", application.sampleText, 1, true, "all" );
	}
	if ( !arrayLen( r ) ) throw "refind-email: no matches";
</cfscript>
