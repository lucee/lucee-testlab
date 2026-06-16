<cfscript>
	q = application.q_n20k;
	r = queryExecute( "SELECT id, val FROM q WHERE id > 0", {}, { dbtype: "query" } );
</cfscript>
