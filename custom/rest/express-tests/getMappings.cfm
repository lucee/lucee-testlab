<cfscript>
	echo(serializeJson( var=getApplicationSettings().mappings, compact=false ));
</cfscript>