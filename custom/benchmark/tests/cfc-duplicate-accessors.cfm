<cfscript>
	if ( !structKeyExists( request, "_proto" ) ) {
		request._proto = new res.PropertiesAccessorsCFC();
	}
	proto = request._proto;
	loop times=10 {
		c = duplicate( proto );
	}
</cfscript>
