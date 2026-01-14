<cfscript>
	q = queryNew( "id,name,data", "integer,varchar,varchar" );
	names= [ 'micha', 'zac', 'brad', 'pothys', 'gert' ];
	loop array="#names#" item="n" {
		r = queryAddRow( q );
		querySetCell( q, "id", r, r );
		querySetCell( q, "name", n, r );
	}
	// native engine
	q_native = QueryExecute(
		sql = "SELECT id, name FROM q ORDER BY name",
		options = { dbtype: 'query' }
	);	
</cfscript>