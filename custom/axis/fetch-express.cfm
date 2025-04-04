<cfscript>
	requestVersion = server.system.environment.fetch ?: "missing!!";
	systemOutput("Fetching express [#requestVersion#]", true);
	
	destDir = expandPath("../../lucee-express-cache/" );
	systemOutput(" Cache dir: " & destDir, true);
	if ( !directoryExists( destDir ) )
		directoryCreate( destDir );

	http url="https://update.lucee.org/rest/update/provider/latest/#listDeleteAt(requestVersion, 3, "/")#/express/info"	result="json";

	versionInfo = deserializeJson(json.filecontent);
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

	expressDir = expandPath("../../express/" );
	directoryCreate( expressDir )
	systemOutput("extracting express into [#expressDir#]", true);
	zip action="unzip" destination="#expressDir#" file="#destDir#/#versionInfo.filename#";

	systemOutput("Directory List [#expressDir#]", true);
	systemOutput(directoryList(path=expressDir, recurse=true), true);

	webroot = expandPath("../../express/webapps/ROOT");
	systemOutput("copying test files into webroot [#webroot#]", true);
	DirectoryCopy(expandPath("../../express-tests/"), webroot);
	systemOutput(directoryList(path=webroot, recurse=true), true);

</cfscript>