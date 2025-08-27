<cfadmin 
	action="getMappings"
	type="server"
	password="webweb"
	returnVariable="srcMappings">
<cfscript>
	mappings = {};
	for (mapping in srcMappings){
		mappings[mapping.virtual] = mapping.physical;
	}
	echo(serializeJson( var=mappings, compact=false ));
</cfscript>