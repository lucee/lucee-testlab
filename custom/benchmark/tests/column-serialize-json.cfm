<cfscript>
	// serializeJSON on a 20-column × 200-row query
	cols = [];
	types = [];
	loop from=1 to=20 index="i" {
		cols.append( "col_#i#" );
		types.append( "varchar" );
	}
	q = queryNew( cols.toList(), types.toList() );
	loop times=200 {
		r = queryAddRow( q );
		loop from=1 to=20 index="i" {
			querySetCell( q, "col_#i#", "value_#r#_#i#", r );
		}
	}
	json = serializeJSON( q );
	if ( len( json ) < 100 )
		throw "serialization failed";
</cfscript>
