<cfscript>
	
	systemOutput("---- saving default .CFConfig.json ---", true);
	if ( !fileExists( expandPath( '{lucee-config}.CFConfig.json' ) ) ){
		systemOutput("File not found [#expandPath('{lucee-config}.CFConfig.json')#] maybe LUCEE_BASE_CONFIG?", true);
	} else {
		cfconfig = deserializeJSON( fileRead( expandPath('{lucee-config}.CFConfig.json') ) );
		systemOutput( serializeJson(var=cfconfig, compact=false), true );
		defaultConfig = getDirectoryFromPath(getCurrentTemplatePath()) & "/.CFConfig-default.json";
		fileWrite( defaultConfig, serializeJson(var=cfconfig, compact=false));
	}

</cfscript>