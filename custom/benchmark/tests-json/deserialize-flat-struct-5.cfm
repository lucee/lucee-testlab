<cfscript>
	loop times=#application.innerLoop# {
		r = deserializeJson( application.flatStruct5 );
	}
	if ( structCount( r ) != 5 ) throw "flat-struct-5 failed";
</cfscript>
