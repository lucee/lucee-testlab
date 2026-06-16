<cfscript>
	q = application.q_grp_20k;
	r = queryExecute( "SELECT DISTINCT category FROM q", {}, { dbtype: "query" } );
</cfscript>
