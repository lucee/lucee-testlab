<cfscript>
	// QoQ on a wider query — 15 columns × 200 rows, select + where + order
	cols = [];
	types = [];
	loop from=1 to=15 index="i" {
		cols.append( "col_#i#" );
		types.append( "varchar" );
	}
	q = queryNew( cols.toList(), types.toList() );
	loop times=200 {
		r = queryAddRow( q );
		loop from=1 to=15 index="i" {
			querySetCell( q, "col_#i#", "v#r#_#i#", r );
		}
	}

	// native QoQ — select subset
	result = queryExecute(
		sql = "SELECT col_1, col_5, col_10, col_15 FROM q WHERE col_1 LIKE :filter ORDER BY col_5",
		params = { filter: { value: "v1%", cfsqltype: "varchar" } },
		options = { dbtype: "query" }
	);

	if ( result.recordcount < 10 )
		throw "expected at least 10 rows, got #result.recordcount#";
</cfscript>
