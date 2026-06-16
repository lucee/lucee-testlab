<cfscript>
	loop times=#application.innerLoop# {
		r = deserializeJson( application.unquotedKeys );
	}
	if ( structCount( r ) != 10 ) throw "unquoted-keys failed";
</cfscript>
