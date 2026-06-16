<cfscript>
	loop times=#application.innerLoop# {
		r = deserializeJson( application.apiResponse );
	}
	if ( r.status != "ok" || arrayLen( r.data ) != 5 ) throw "api-response failed";
</cfscript>
