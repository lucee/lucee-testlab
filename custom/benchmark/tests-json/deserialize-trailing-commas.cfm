<cfscript>
	loop times=#application.innerLoop# {
		r = deserializeJson( application.trailingCommas );
	}
	if ( arrayLen( r ) != 5 ) throw "trailing-commas failed";
</cfscript>
