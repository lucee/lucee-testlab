<cfscript>
	requestVersion = server.system.environment.fetch ?: "missing!!";
	systemOutput("Fetching express [#requestVersion#]", true);
	
	destDir = expandPath("../../lucee-express-cache/" );
	systemOutput(" Cache dir: " & destDir, true);
	if ( !directoryExists( destDir ) )
		directoryCreate( destDir )

	http url="https://update.lucee.org/rest/update/provider/latest/#listDeleteAt(requestVersion, 3, "/")#/express/info"	result="json";

	var versionInfo = deserializeJson(json.filecontent);
	/*
		{
			version: "6.0.4.24-SNAPSHOT",
			filename: "lucee-express-6.0.4.24-SNAPSHOT.zip",
			url: "https://cdn.lucee.org/lucee-express-6.0.4.24-SNAPSHOT.zip"
		}
	*/
	systemOutput( versionInfo, true );

	if ( fileExists( destDir & versionInfo.filename ) ) {
		systemOutput( "Already cached: " & versionInfo.filename, true );
	} else {
		systemOutput( "Downloading: " & versionInfo.url, true );
		http url="#versionInfo.url#" path="#destDir#" file="#versionInfo.filename#";
	}

	systemOutput( fileInfo("#destDir#/#versionInfo.filename#"), true );

</cfscript>