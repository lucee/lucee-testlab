<cfscript>
	q = application.q_grp_1k;
	r = queryExecute( "SELECT DISTINCT category FROM q", {}, { dbtype: "query" } );
</cfscript>
