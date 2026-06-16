component {

	this.name = "bench-qoq-#hash( getCurrentTemplatePath() )#";
	this.sessionManagement = false;

	function onApplicationStart() {

		application.q_n50    = buildNarrow( 50 );
		application.q_n200   = buildNarrow( 200 );
		application.q_n1k    = buildNarrow( 1000 );
		application.q_n5k    = buildNarrow( 5000 );
		application.q_n20k   = buildNarrow( 20000 );

		application.q_w50    = buildWide( 50 );
		application.q_w1k    = buildWide( 1000 );
		application.q_w20k   = buildWide( 20000 );

		// Grouped queries — adds a category column with 5 distinct values for GROUP BY / DISTINCT
		application.q_grp_1k  = buildGrouped( 1000 );
		application.q_grp_20k = buildGrouped( 20000 );

		// Union pair — same shape, partial id overlap so UNION DISTINCT has dedup work to do
		application.q_u1 = buildUnionSource( 1000, 1 );      // ids 1-1000
		application.q_u2 = buildUnionSource( 1000, 500 );    // ids 500-1499

		systemOutput( "QoQ benchmark source queries built (narrow, wide, grouped, union)", true );
	}

	private query function buildNarrow( required numeric rows ) {
		var q = queryNew( "id,val", "integer,varchar" );
		loop from=1 to=arguments.rows index="local.i" {
			var r = queryAddRow( q );
			querySetCell( q, "id",  i,                r );
			querySetCell( q, "val", "row_" & i,       r );
		}
		return q;
	}

	private query function buildGrouped( required numeric rows ) {
		var q = queryNew( "id,val,category", "integer,varchar,varchar" );
		var cats = [ "alpha", "beta", "gamma", "delta", "epsilon" ];
		loop from=1 to=arguments.rows index="local.i" {
			var r = queryAddRow( q );
			querySetCell( q, "id",       i,                                r );
			querySetCell( q, "val",      "row_" & i,                       r );
			querySetCell( q, "category", cats[ ((i-1) mod 5) + 1 ],        r );
		}
		return q;
	}

	private query function buildUnionSource( required numeric rows, required numeric startId ) {
		var q = queryNew( "id,val", "integer,varchar" );
		loop from=1 to=arguments.rows index="local.i" {
			var r = queryAddRow( q );
			querySetCell( q, "id",  arguments.startId + i - 1,            r );
			querySetCell( q, "val", "u_" & ( arguments.startId + i - 1 ), r );
		}
		return q;
	}

	private query function buildWide( required numeric rows ) {
		var q = queryNew(
			"id,c1,c2,c3,c4,c5,c6,c7,c8,c9",
			"integer,varchar,varchar,varchar,varchar,varchar,varchar,varchar,varchar,varchar"
		);
		loop from=1 to=arguments.rows index="local.i" {
			var r = queryAddRow( q );
			querySetCell( q, "id", i, r );
			loop from=1 to=9 index="local.j" {
				querySetCell( q, "c" & j, "r" & i & "_c" & j, r );
			}
		}
		return q;
	}
}
