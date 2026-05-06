<cfscript>
	// Note: does NOT clear existing mappings -- meant to be called AFTER
	// setupRestPrefixOverlap.cfm (which does the clear) so both mappings
	// coexist for the LDEV-6306 test matrix.
	dir = getDirectoryFromPath( getCurrentTemplatePath() );
	restInitApplication( dir, "/restDuplicates", false, "webweb" );
	new "../restUtils"().dumpRestConfig();
</cfscript>
