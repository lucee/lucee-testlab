<cfscript>
	// Sustained ~41KB document, 500 records, byte-identical to ser-big's output and
	// to tests-json's big fixture. Mixed: 1000 numbers (id, value), 1000 strings,
	// 2500 keys, 500 booleans per parse. Unlike ser-big this cell HAS an inner loop;
	// ser-big's 26% run-to-run spread was traced to it being the only cell without one.
	d = application.big;
	n = application.jdLoopMid;
	for ( i = 1; i <= n; i++ ) {
		r = deserializeJson( d );
	}
	if ( arrayLen( r ) != 500 || r[ 500 ].id != 500 ) throw "big failed";
</cfscript>
