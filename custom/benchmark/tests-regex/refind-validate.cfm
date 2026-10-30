<cfscript>
	n = application.shortLoop;
	loop times=#n# {
		r = reFindNoCase( "^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$", "zac@example.com" );
	}
	if ( r != 1 ) throw "refind-validate: expected 1, got #r#";
</cfscript>
