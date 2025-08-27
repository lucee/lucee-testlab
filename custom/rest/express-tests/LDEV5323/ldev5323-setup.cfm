<cfscript>
	new "../restUtils"().clearRestMappings();
	dir = getDirectoryFromPath(getCurrentTemplatePath());
	RestInitApplication( dir,            '/ldev5323root', false, "webweb" );
	RestInitApplication( dir & "subdir", '/ldev5323sub',  false, "webweb" );
	new "../restUtils"().dumpRestConfig();
</cfscript>