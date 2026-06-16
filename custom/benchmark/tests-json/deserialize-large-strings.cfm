<cfscript>
	loop times=#application.innerLoop# {
		r = deserializeJson( application.largeStrings );
	}
	if ( structCount( r ) != 10 ) throw "large-strings failed";
</cfscript>
