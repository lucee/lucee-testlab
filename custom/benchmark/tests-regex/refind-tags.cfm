<cfscript>
	loop times=#application.innerLoop# {
		r = reFindNoCase( "\[[a-z/]+\]", application.sampleText, 1, true, "all" );
	}
	if ( !arrayLen( r ) ) throw "refind-tags: no matches";
</cfscript>
