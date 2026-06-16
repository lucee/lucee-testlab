<cfscript>
	q = application.q_n1k;
	r = queryExecute( "SELECT id, val FROM q ORDER BY val", {}, { dbtype: "query" } );
</cfscript>
