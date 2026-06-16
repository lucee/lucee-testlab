<cfscript>
	loop times=#application.innerLoop# {
		r = deserializeJson( application.array100Ints );
	}
	if ( arrayLen( r ) != 100 ) throw "array-100 failed";
</cfscript>
