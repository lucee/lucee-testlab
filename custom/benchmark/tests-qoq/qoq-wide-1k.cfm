<cfscript>
	q = application.q_w1k;
	r = queryExecute( "SELECT * FROM q WHERE id > 0", {}, { dbtype: "query" } );
</cfscript>
