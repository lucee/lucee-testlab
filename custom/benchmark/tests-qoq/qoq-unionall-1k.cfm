<cfscript>
	q1 = application.q_u1;
	q2 = application.q_u2;
	r = queryExecute( "SELECT id, val FROM q1 UNION ALL SELECT id, val FROM q2", {}, { dbtype: "query" } );
</cfscript>
