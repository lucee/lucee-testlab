<cfscript>
	// querySort with UDF + queryToStruct on 20 columns × 300 rows
	cols = [];
	types = [];
	loop from=1 to=20 index="i" {
		cols.append( "col_#i#" );
		types.append( "varchar" );
	}
	q = queryNew( cols.toList(), types.toList() );
	loop times=300 {
		r = queryAddRow( q );
		loop from=1 to=20 index="i" {
			querySetCell( q, "col_#i#", "v#r#_#i#", r );
		}
	}

	// querySort with UDF comparator — builds struct per row, getAt per column
	sorted = duplicate( q );
	querySort( sorted, function( a, b ) {
		return compare( a.col_10, b.col_10 );
	} );

	// queryToStruct — getAt per column per row
	sct = queryToStruct( sorted, "col_1" );

	if ( structCount( sct ) < 100 )
		throw "expected at least 100 keys, got #structCount( sct )#";
</cfscript>
