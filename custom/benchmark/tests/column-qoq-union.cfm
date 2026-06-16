<cfscript>
	// QoQ UNION — exercises doUnionAll pre-resolve fix
	q1 = queryNew( "id,name,status,dept,score", "integer,varchar,varchar,varchar,integer" );
	q2 = queryNew( "id,name,status,dept,score", "integer,varchar,varchar,varchar,integer" );
	loop times=100 {
		r = queryAddRow( q1 );
		querySetCell( q1, "id", r, r );
		querySetCell( q1, "name", "user_a#r#", r );
		querySetCell( q1, "status", "active", r );
		querySetCell( q1, "dept", "eng", r );
		querySetCell( q1, "score", r * 10, r );
	}
	loop times=100 {
		r = queryAddRow( q2 );
		querySetCell( q2, "id", r + 100, r );
		querySetCell( q2, "name", "user_b#r#", r );
		querySetCell( q2, "status", "inactive", r );
		querySetCell( q2, "dept", "sales", r );
		querySetCell( q2, "score", r * 5, r );
	}

	result = queryExecute(
		sql = "SELECT id, name, status, dept, score FROM q1 UNION ALL SELECT id, name, status, dept, score FROM q2",
		options = { dbtype: "query" }
	);

	if ( result.recordcount != 200 )
		throw "expected 200 rows, got #result.recordcount#";
</cfscript>
