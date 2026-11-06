component {

	this.name = "bench-json-serialize";
	this.sessionManagement = false;

	function onApplicationStart() {

		// ---------------------------------------------------------------------------
		// Per-cycle inner loop counts. Unlike tests-cachedwithin, nothing in this
		// family contends on a shared monitor — escapeJS touches no static formatter,
		// and every JSONConverter is a fresh local instance. So this is a per-call CPU
		// and allocation question, and the harness's ~50-500us cycle guidance applies
		// as written: keep counts low enough to stay in the band, push cycles up.
		//
		// Two counts because per-call cost differs by ~2 orders of magnitude across
		// the family. Retune both in the opposite direction to BENCHMARK_CYCLES to
		// hold total work constant.
		// ---------------------------------------------------------------------------
		application.jsLoopSmall = int( server.system.environment.JS_LOOP_SMALL ?: 50 );
		application.jsLoopMid = int( server.system.environment.JS_LOOP_MID ?: 10 );

		// --- control: no escapeJS calls at all -------------------------------------
		// 1000 integers. serializeJSON walks the array, appends numbers, and never
		// reaches escapeJS once. Any escapeJS change that moves THIS cell has done
		// something unintended.
		var nums = [];
		for ( var i = 1; i <= 1000; i++ ) arrayAppend( nums, i );
		application.numbersArray = nums;

		// --- call-count axis: many short keys, tiny values --------------------------
		// 200 keys of ~6 ASCII chars. Maximises escapeJS CALLS per serialized byte,
		// which is what the presize and Appendable-overload changes remove work from.
		var wide = {};
		for ( var i = 1; i <= 200; i++ ) wide[ "key" & i ] = i;
		application.wideStruct200 = wide;

		// --- char-count axis: few keys, long clean values ---------------------------
		// 10 keys, each ~4KB of pure ASCII needing zero escaping. Maximises CHARS per
		// escapeJS call, which is what dropping toCharArray() and the no-escape fast
		// path remove work from. Deliberately clean so the fast path is reachable.
		var clean = {};
		for ( var i = 1; i <= 10; i++ ) {
			clean[ "field" & i ] = repeatString( "lorem ipsum dolor sit amet consectetur ", 105 );
		}
		application.longStringsClean = clean;

		// --- same shape and size, dense escapes ------------------------------------
		// A/B partner for longStringsClean. Same key count, same value length, but
		// one char in three needs an escape branch (14-char unit, 5 escapes), so the
		// no-escape fast path never fires and the per-char switch runs to completion.
		// The ratio between these two cells IS the cost of the escape branching.
		var dirty = {};
		var unit = 'say "hi" a\b' & chr( 9 ) & "c" & chr( 10 );
		for ( var i = 1; i <= 10; i++ ) {
			dirty[ "field" & i ] = repeatString( unit, 285 );
		}
		application.longStringsEscaped = dirty;

		// --- worst case for a whole-string clean scan --------------------------------
		// Same 4KB clean value as longStringsClean with a single quote at the very end.
		// A "scan for the first char needing work, bulk-append if none" design pays a
		// full wasted scan here and then the whole per-char pass. This cell is the
		// upper bound on that design's downside; late / clean is the cost of the scan.
		var late = {};
		for ( var i = 1; i <= 10; i++ ) {
			late[ "field" & i ] = repeatString( "lorem ipsum dolor sit amet consectetur ", 105 ) & '"';
		}
		application.longStringsLateEscape = late;

		// --- realistic density: prose with an occasional quote ------------------------
		// one char in 50 needs an escape (100-char unit, 2 quotes), which is what string values in real payloads
		// look like. Sits between clean (0) and escaped (1 in 3). Any bulk-append
		// design that chunks between escapes is judged here, not on the dense cell.
		var sparse = {};
		var prose = 'lorem ipsum dolor sit amet "consectetur" adipiscing elit sed do eiusmod tempor incididunt ut labore ';
		for ( var i = 1; i <= 10; i++ ) {
			sparse[ "field" & i ] = repeatString( prose, 42 );
		}
		application.longStringsSparse = sparse;

		// --- realistic escape-heavy: JSON stored as a string value ------------------
		// API passthrough and cached-payload shapes do this constantly — a JSON
		// document held as a value inside another struct, so every quote in it gets
		// escaped on the way out. More representative than longStringsEscaped.
		var inner = { "status": "ok", "items": [ 1, 2, 3 ], "note": "nested payload" };
		var embedded = {};
		for ( var i = 1; i <= 20; i++ ) {
			embedded[ "payload" & i ] = serializeJson( inner );
		}
		application.embeddedJson = embedded;

		// --- non-ASCII, built with chr() so this file stays pure ASCII ---------------
		// Latin-1 accents plus CJK. Under the default web charset (UTF-8) the encoder
		// canEncode() every one of these, so escapeJS appends them raw and its local
		// LATIN1 StringBuilder inflates to UTF16 on the first one. That is the path
		// compact-string-inflation-hotspots.md measured at 301 events in the test
		// suite JFR and could not see in the preside/wheels soaks, because that data
		// is ASCII. This cell is where it becomes visible on demand.
		var accents = chr( 233 ) & chr( 224 ) & chr( 246 ) & chr( 241 ) & chr( 229 );
		var cjk = chr( 20013 ) & chr( 25991 ) & chr( 12354 ) & chr( 12356 );
		var nonAscii = {};
		for ( var i = 1; i <= 20; i++ ) {
			nonAscii[ "text" & i ] = repeatString( "ascii prefix " & accents & " middle " & cjk & " suffix ", 12 );
		}
		application.nonAsciiValues = nonAscii;

		// --- realistic mixed payload -----------------------------------------------
		// Same shape as tests-json's apiResponse fixture, kept as the live CFML object
		// rather than its serialized string, so ser-api-response and
		// deserialize-api-response can be read as a cross-family pair on one payload.
		var api = {
			"status": "ok",
			"timestamp": "2026-06-10T23:00:00Z",
			"count": 5,
			"data": []
		};
		for ( var i = 1; i <= 5; i++ ) {
			arrayAppend( api.data, {
				"id": i,
				"name": "User #i#",
				"email": "user#i#@example.com",
				"age": 25 + i,
				"active": ( i mod 2 ) == 0,
				"tags": [ "tag-a", "tag-b", "tag-c" ],
				"meta": { "created": "2026-01-01", "score": i * 1.5 }
			} );
		}
		application.apiResponse = api;

		// --- query: the shape a remote CFC returns ---------------------------------
		// 50 rows x 8 columns. The three queryFormat modes emit column names a
		// different number of times, which is the cleanest available lever on
		// escapeJS call count at fixed payload size — see the README table.
		var q = queryNew(
			"id,name,email,city,country,status,created,score",
			"integer,varchar,varchar,varchar,varchar,varchar,varchar,double"
		);
		for ( var i = 1; i <= 50; i++ ) {
			queryAddRow( q, {
				"id": i,
				"name": "Person #i#",
				"email": "person#i#@example.com",
				"city": "Melbourne",
				"country": "Australia",
				"status": ( i mod 2 ) == 0 ? "active" : "pending",
				"created": "2026-01-0#( i mod 9 ) + 1#",
				"score": i * 1.5
			} );
		}
		application.rows = q;

		// --- binary: base64 encode plus the JSONConverter:800 double concat ---------
		// 64KB, matching LDEV-6052's benchmark payload size so the numbers are
		// comparable. Exercises the hand-rolled Base64Encoder (char[4] per 3 bytes)
		// and the "\"" + encoded + "\"" concat that copies the whole base64 again.
		var bin = [];
		for ( var i = 1; i <= 65536; i++ ) arrayAppend( bin, ( i mod 256 ) - 128 );
		application.binaryValue = javacast( "byte[]", bin );

		// --- binary, multi-MB: the humongous-allocation shape ------------------------
		// 4MB byte[] -> ~5.6MB base64. Every whole-payload copy on the binary path
		// (encode, the quote concat, the outer append, toString) is a G1 humongous
		// allocation at this size, so removing one is a GC-shape change, not a
		// throughput one. Read this cell on GC count and pause, not ms. Milliseconds
		// per call, so it is NOT in the family run: BENCHMARK_FILTER=ser-binary-big
		// with BENCHMARK_CYCLES=1 or so.
		application.binaryBig = charsetDecode( repeatString( "abcdefgh", 524288 ), "utf-8" );

		// --- sustained: ~50KB out, mirrors tests-json's big fixture -----------------
		var bigArr = [];
		for ( var i = 1; i <= 500; i++ ) {
			arrayAppend( bigArr, {
				"id": i,
				"name": "Record #i#",
				"value": i * 3.14159,
				"active": ( i mod 3 ) == 0,
				"category": [ "cat-a", "cat-b" ][ ( i mod 2 ) + 1 ]
			} );
		}
		application.big = bigArr;

		systemOutput(
			"JSON serialize bench seeded"
			& " — wide: 200 keys"
			& ", clean: " & numberFormat( len( application.longStringsClean.field1 ) ) & " chars/value"
			& ", escaped: " & numberFormat( len( application.longStringsEscaped.field1 ) ) & " chars/value"
			& ", binary: " & numberFormat( arrayLen( bin ) / 1024, "0.0" ) & "KB"
			& ", big: " & numberFormat( len( serializeJson( application.big ) ) / 1024, "0.0" ) & "KB out"
			, true
		);
	}

}
