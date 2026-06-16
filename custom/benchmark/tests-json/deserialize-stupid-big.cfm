<cfscript>
	r = deserializeJson( application.stupidBig );
	if ( arrayLen( r ) != 5000 ) throw "stupid-big failed";
</cfscript>
