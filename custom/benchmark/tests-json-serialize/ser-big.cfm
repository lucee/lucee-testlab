<cfscript>
	// Sustained ~50KB output, 500 records x 5 keys = 2500 key calls plus 1000 string
	// values per serialize. Mirrors tests-json/deserialize-big. No inner loop — one
	// serialize already puts a cycle in the harness band.
	//
	// This is the cell where the outer single-StringBuilder accumulation that
	// compact-string-inflation-hotspots.md wants streamed to a Writer starts to
	// show as grow-and-copy, though at 50KB it is nowhere near the 120MB events
	// that doc recorded.
	s = serializeJson( application.big );
	if ( len( s ) < 40000 ) throw "big failed";
</cfscript>
