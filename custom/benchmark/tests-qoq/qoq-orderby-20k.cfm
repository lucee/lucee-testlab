<cfscript>
	q = application.q_n20k;
	r = queryExecute( "SELECT id, val FROM q ORDER BY val", {}, { dbtype: "query" } );
</cfscript>
