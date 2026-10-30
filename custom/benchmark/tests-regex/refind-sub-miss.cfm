<cfscript>
	n = application.shortLoop;
	loop times=#n# {
		r = reFind( "([a-z]+)-([0-9]+)", "item abc 123", 1, true );
	}
	if ( r.pos[ 1 ] != 0 ) throw "refind-sub-miss: expected pos 0, got #r.pos[ 1 ]#";
</cfscript>
