<cfscript>
	loop times=#application.innerLoop# {
		r = deserializeJson( application.flatArray10 );
	}
	if ( arrayLen( r ) != 10 ) throw "flat-array-10 failed";
</cfscript>
