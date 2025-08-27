<cfscript>
	new "../resutUtils"().clearRestMappings();
	dir = getDirectoryFromPath(getCurrentTemplatePath()) & "LDEV5324/"
	RestInitApplication( dir, '/ldev5324', false, "webweb" );
	new "../resutUtils"().dumpRestConfig();
</cfscript>