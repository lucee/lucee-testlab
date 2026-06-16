<cfscript>
	if ( !structKeyExists( request, "_protoMixed" ) ) {
		request._protoMixed = new res.PropertiesAccessorsCFCmixed();
	}
	proto = request._protoMixed;
	loop times=10 {
		c = duplicate( proto );
	}
</cfscript>
