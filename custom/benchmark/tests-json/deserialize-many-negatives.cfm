<cfscript>
	loop times=#application.innerLoop# {
		r = deserializeJson( application.manyNegatives );
	}
	if ( arrayLen( r ) != 50 || r[ 1 ] != -1 ) throw "many-negatives failed";
</cfscript>
