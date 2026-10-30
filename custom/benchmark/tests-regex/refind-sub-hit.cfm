<cfscript>
	n = application.shortLoop;
	loop times=#n# {
		r = reFind( "([a-z]+)-([0-9]+)", "item abc-123", 1, true );
	}
	if ( r.pos[ 1 ] != 6 ) throw "refind-sub-hit: expected pos 6, got #r.pos[ 1 ]#";
</cfscript>
