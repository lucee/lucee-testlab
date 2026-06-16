<cfscript>
	q = application.q_w50;
	r = queryExecute( "SELECT * FROM q WHERE id > 0", {}, { dbtype: "query" } );
</cfscript>
