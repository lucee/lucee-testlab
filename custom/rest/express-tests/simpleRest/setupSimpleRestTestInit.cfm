<cfscript>
	new "../restUtils"().clearRestMappings();
	restPath = expandPath( getDirectoryFromPath( getCurrentTemplatePath() ) );
	RestInitApplication( restPath, '/simpleRestInit', true, "webweb" );
	new "../restUtils"().dumpRestConfig();
</cfscript>