<cfscript>
	q = queryNew( "id,name,data", "integer,varchar,varchar" );
	names= [ 'micha', 'zac', 'brad', 'pothys', 'gert' ];
	loop array="#names#" item="n" {
		r = queryAddRow( q );
		querySetCell( q, "id", r, r );
		querySetCell( q, "name", n, r );
	}
	// hsqldb engine, coz join
	q_hsqlb = QueryExecute(
		sql = "SELECT t1.name FROM q t1, q t2 WHERE t1.id = t2.id",
		options = { dbtype: 'query' }
	);
</cfscript>