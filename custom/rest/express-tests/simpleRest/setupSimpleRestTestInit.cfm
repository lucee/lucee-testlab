<cfscript>
	restPath = expandPath( getDirectoryFromPath( getCurrentTemplatePath() ) );
	RestInitApplication( restPath, '/simpleRestInit', true, "webweb" );
	new "../dumpRestConfig"().dumpRestConfig();
</cfscript>