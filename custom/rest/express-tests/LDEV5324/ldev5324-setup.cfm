<cfscript>
	new "../restUtils"().clearRestMappings();
	dir = getDirectoryFromPath(getCurrentTemplatePath());
	RestInitApplication( dir, '/ldev5324', false, "webweb" );
	new "../restUtils"().dumpRestConfig();
</cfscript>