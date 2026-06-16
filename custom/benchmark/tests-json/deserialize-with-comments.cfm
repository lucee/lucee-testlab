<cfscript>
	loop times=#application.innerLoop# {
		r = deserializeJson( application.withComments );
	}
	if ( structCount( r ) != 3 ) throw "with-comments failed";
</cfscript>
