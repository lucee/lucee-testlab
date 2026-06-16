<cfscript>
	loop times=#application.innerLoop# {
		r = deserializeJson( application.leadingPlus );
	}
	if ( arrayLen( r ) != 10 || r[ 1 ] != 1 ) throw "leading-plus failed";
</cfscript>
