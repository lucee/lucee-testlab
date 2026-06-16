<cfscript>
	// for-in loop over 25 columns × 400 rows — the ForEachQueryIterator path
	cols = [];
	types = [];
	loop from=1 to=25 index="i" {
		cols.append( "col_#i#" );
		types.append( "varchar" );
	}
	q = queryNew( cols.toList(), types.toList() );
	loop times=400 {
		r = queryAddRow( q );
		loop from=1 to=25 index="i" {
			querySetCell( q, "col_#i#", "v#r#_#i#", r );
		}
	}

	total = 0;
	for ( row in q ) {
		total += len( row.col_1 ) + len( row.col_13 ) + len( row.col_25 );
	}
</cfscript>
