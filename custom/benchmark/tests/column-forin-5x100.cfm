<cfscript>
	// realistic: for-in loop, 5 columns × 100 rows
	q = queryNew( "id,name,email,status,created", "integer,varchar,varchar,varchar,timestamp" );
	loop times=100 {
		r = queryAddRow( q );
		querySetCell( q, "id", r, r );
		querySetCell( q, "name", "user_#r#", r );
		querySetCell( q, "email", "user#r#@example.com", r );
		querySetCell( q, "status", r mod 2 ? "active" : "inactive", r );
		querySetCell( q, "created", now(), r );
	}

	total = 0;
	for ( row in q ) {
		total += len( row.name ) + len( row.email ) + len( row.status );
	}
</cfscript>
