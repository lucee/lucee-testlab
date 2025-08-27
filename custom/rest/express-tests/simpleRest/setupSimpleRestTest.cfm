<cfscript>
	restPath = expandPath( getDirectoryFromPath( getCurrentTemplatePath() ) );
	
	cfadmin(action="updateRestMapping",
		type="server",
		password="webweb",
		virtual="simpleRest",
		physical=restPath,
		default="false"
	);

	cfadmin(action="updateRestSettings",
			type="server",
			password="webweb",
			list="true"
	);
	new "../dumpRestConfig"().dumpRestConfig();
</cfscript>