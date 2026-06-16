<cfscript>
	if ( !structKeyExists( request, "_protoEmpty" ) ) {
		request._protoEmpty = new res.EmptyCFC();
	}
	proto = request._protoEmpty;
	loop times=10 {
		c = duplicate( proto );
	}
</cfscript>
