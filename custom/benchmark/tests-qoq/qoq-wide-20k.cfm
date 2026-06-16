<cfscript>
	q = application.q_w20k;
	r = queryExecute( "SELECT * FROM q WHERE id > 0", {}, { dbtype: "query" } );
</cfscript>
