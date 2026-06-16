<cfscript>
	loop times=#application.innerLoop# {
		r = deserializeJson( application.wideStruct50 );
	}
	if ( structCount( r ) != 50 ) throw "wide-struct-50 failed";
</cfscript>
