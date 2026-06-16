<cfscript>
	q = application.q_grp_1k;
	r = queryExecute( "SELECT category, COUNT(*) AS cnt FROM q GROUP BY category", {}, { dbtype: "query" } );
</cfscript>
