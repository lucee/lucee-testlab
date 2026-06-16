<cfscript>
	// 30 columns × 500 rows — the cfoutput query implicit scoping path
	cols = [];
	types = [];
	loop from=1 to=30 index="i" {
		cols.append( "col_#i#" );
		types.append( "varchar" );
	}
	q = queryNew( cols.toList(), types.toList() );
	loop times=500 {
		r = queryAddRow( q );
		loop from=1 to=30 index="i" {
			querySetCell( q, "col_#i#", "val_#r#_#i#", r );
		}
	}
</cfscript>
<cfset total = 0>
<cfoutput query="q">
	<cfset total += len( col_1 ) + len( col_5 ) + len( col_10 ) + len( col_15 ) + len( col_20 ) + len( col_25 ) + len( col_30 )>
</cfoutput>
