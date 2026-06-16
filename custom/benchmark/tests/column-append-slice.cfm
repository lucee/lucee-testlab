<cfscript>
	// queryAppend + querySlice + queryReverse on 20 columns × 200 rows
	cols = [];
	types = [];
	loop from=1 to=20 index="i" {
		cols.append( "col_#i#" );
		types.append( "varchar" );
	}
	q1 = queryNew( cols.toList(), types.toList() );
	q2 = queryNew( cols.toList(), types.toList() );
	loop times=200 {
		r = queryAddRow( q1 );
		loop from=1 to=20 index="i" {
			querySetCell( q1, "col_#i#", "a#r#_#i#", r );
		}
	}
	loop times=100 {
		r = queryAddRow( q2 );
		loop from=1 to=20 index="i" {
			querySetCell( q2, "col_#i#", "b#r#_#i#", r );
		}
	}

	// queryAppend (copies q2 rows into q1 clone)
	combined = duplicate( q1 );
	queryAppend( combined, q2 );

	// querySlice
	sliced = querySlice( combined, 50, 100 );

	// queryReverse
	reversed = queryReverse( sliced );

	if ( reversed.recordcount != 100 )
		throw "expected 100, got #reversed.recordcount#";
</cfscript>
