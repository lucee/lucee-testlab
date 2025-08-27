<cfscript>
	new "../resutUtils"().clearRestMappings();
	dir = getDirectoryFromPath(getCurrentTemplatePath()) & "LDEV5323/"
	RestInitApplication( dir,            '/ldev5323root', false, "webweb" );
	RestInitApplication( dir & "subdir", '/ldev5323sub',  false, "webweb" );
	new "../resutUtils"().dumpRestConfig();
</cfscript>