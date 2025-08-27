<cfadmin 
	action="getMappings"
	type="server"
	password="webweb"
	returnVariable="mappings">
[<cfscript>
	delim ="";
	for (mapping in mappings){
		echo(delim &chr(10));
		echo(serializeJson( var={"#mapping.virtual#":mapping.physical}, compact=false ));
		delim=",";
	}
</cfscript>]