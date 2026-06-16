<cfscript>
	q = application.q_grp_1k;
	r = queryExecute( "SELECT category, COUNT(*) AS cnt FROM q GROUP BY category HAVING COUNT(*) > 5", {}, { dbtype: "query" } );
</cfscript>
