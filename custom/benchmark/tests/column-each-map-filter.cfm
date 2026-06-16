<cfscript>
	// queryEach / queryMap / queryFilter on 15 columns × 300 rows
	cols = [];
	types = [];
	loop from=1 to=15 index="i" {
		cols.append( "col_#i#" );
		types.append( "varchar" );
	}
	q = queryNew( cols.toList(), types.toList() );
	loop times=300 {
		r = queryAddRow( q );
		loop from=1 to=15 index="i" {
			querySetCell( q, "col_#i#", "v#r#_#i#", r );
		}
	}

	// queryEach
	count = 0;
	queryEach( q, function( row ) {
		count += len( row.col_1 ) + len( row.col_8 ) + len( row.col_15 );
	} );

	// queryFilter
	filtered = queryFilter( q, function( row ) {
		return row.col_1 contains "1";
	} );

	// queryMap
	mapped = queryMap( q, function( row ) {
		row.col_1 = row.col_1 & "_mapped";
		return row;
	} );
</cfscript>
