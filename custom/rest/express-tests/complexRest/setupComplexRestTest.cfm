<cfscript>
	new "../restUtils"().clearRestMappings();
	restPath = expandPath( getDirectoryFromPath( getCurrentTemplatePath() ) );
	
	cfadmin(action="updateRestMapping",
		type="server",
		password="webweb",
		virtual="complexRest",
		physical=restPath,
		default="false"
	);

	cfadmin(action="updateRestSettings",
		type="server",
		password="webweb",
		list="true"
	);
	new "../restUtils"().dumpRestConfig();
</cfscript>