<cfscript>
	new "../restUtils"().clearRestMappings();
	dir = getDirectoryFromPath( getCurrentTemplatePath() );
	restInitApplication( dir, "/restPrefixOverlap", false, "webweb" );
	new "../restUtils"().dumpRestConfig();
</cfscript>
