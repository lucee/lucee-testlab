<cfscript>
	// literal braces, Preside SqlRunner.cfc; java throws "Illegal repetition", so it skips
	if ( getApplicationSettings().regex.type != "java" ) {
		n = application.shortLoop;
		loop times=#n# {
			r = reFindNoCase( "{{base64:([A-Za-z0-9\+\/=]+)}}", "x {{base64:QUJD}} y", 1, true );
		}
		if ( r.pos[ 1 ] != 3 ) throw "refind-braces: expected 3, got #r.pos[ 1 ]#";
	}
</cfscript>
