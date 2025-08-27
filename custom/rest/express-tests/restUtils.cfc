component {
	function dumpRestConfig(){
		cfadmin(action="getRestMappings",
			type="server",
			password="webweb",
			returnVariable="local.rest");
		logger( "---------------rest mappings------------" );
		for (var r in rest){
			logger( r );
			logger( r.strphysical );
			logger( "Exists:" & directoryExists( r.strphysical ) );
			logger( "CFCs:" & serializeJson( directoryList( r.strphysical ) ) );
			logger( "" );
		}

		var cfconfig = DeSerializeJson(fileRead( expandPath('{lucee-config}.CFConfig.json') ) );
		logger( "---------------cfconfig------------" );
		var rest = cfconfig.rest ?: { "restConfigMissing": true };
		logger( serializeJson( var=rest, compact=false ) );
	}

	function logger(mess){
		systemOutput( mess, true );
		if (isSimpleValue(mess))
			echo( mess & chr(10 ) );
		else
			echo (serializeJSON(mess) & chr(10));
	}

	function clearRestMappings (){
		cfadmin(action="getRestMappings",
			type="server",
			password="webweb",
			returnVariable="local.rest");
		logger( "---------------deleteing mappings------------" );
		for (var r in rest){
			RestDeleteApplication( dirPath=r.strphysical, password="webweb" );
		}
	}
}