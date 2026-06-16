component {

	this.name = "bench-json";
	this.sessionManagement = false;

	function onApplicationStart() {

		// Inner-loop multiplier for small/mid tests. Each cycle does N parses to amortise
		// harness overhead (request setup) across more work. Big/stupid-big skip this since
		// they're already long per cycle. Reported "k/s" is cycles/sec; actual parses/sec = k/s * innerLoop.
		application.innerLoop = 10;

		// Seed JSON fixtures into application scope once. Tests read these strings
		// and call deserializeJson on them in a tight loop.

		// --- single-value parses (minimum-path) ---
		application.singleString = '"hello world"';
		application.singleNumber = "12345.678";
		application.singleBool   = "true";
		application.singleNull   = "null";

		// --- tight flat structures ---
		application.flatArray10  = "[1,2,3,4,5,6,7,8,9,10]";
		application.flatStruct5  = '{"a":1,"b":2,"c":3,"d":4,"e":5}';

		// --- medium arrays / structs ---
		var arr100 = [];
		for ( var i = 1; i <= 100; i++ ) arrayAppend( arr100, i );
		application.array100Ints = serializeJson( arr100 );

		var wide = {};
		for ( var i = 1; i <= 50; i++ ) wide[ "key" & i ] = i;
		application.wideStruct50 = serializeJson( wide );

		// --- deeply nested ---
		var nested = 1;
		for ( var i = 1; i <= 10; i++ ) nested = [ nested ];
		application.nested10 = serializeJson( nested );

		// --- realistic mixed payload (~2KB) ---
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
		application.apiResponse = serializeJson( api );

		// --- string-heavy struct (escape handling) ---
		var strs = {};
		for ( var i = 1; i <= 10; i++ ) {
			strs[ "field" & i ] = repeatString( "lorem ipsum dolor sit amet ", 20 );
		}
		application.largeStrings = serializeJson( strs );

		// --- many signed numbers (signedNumber path) ---
		var negs = [];
		for ( var i = 1; i <= 50; i++ ) arrayAppend( negs, -i );
		application.manyNegatives = serializeJson( negs );

		// --- JSON5 surface (exercises restricted-entry's Case 2 / comments / etc) ---
		// build manually — serializeJson would quote keys / strip commas
		application.unquotedKeys   = "{a:1,b:2,c:3,d:4,e:5,f:6,g:7,h:8,i:9,j:10}";
		application.withComments   = '{/* head */"a":1,"b":2 /* mid */,"c":3 // tail' & chr(10) & "}";
		application.trailingCommas = "[1,2,3,4,5,]";
		application.leadingPlus    = "[+1,+2,+3,+4,+5,+6,+7,+8,+9,+10]";

		// --- BIG: ~50KB ---
		// 500 records, each ~100 bytes. Stresses jsonElements loop + BIFCall construction at scale.
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
		application.big = serializeJson( bigArr );

		// --- STUPID BIG: ~500KB ---
		// 5000 records of the same shape. Stresses sustained allocation / GC pressure / long jsonElements loop.
		// Bench cycles will be slow on this one — operator should lower BENCHMARK_CYCLES if running locally.
		var stupidBigArr = [];
		for ( var i = 1; i <= 5000; i++ ) {
			arrayAppend( stupidBigArr, {
				"id": i,
				"name": "Record #i#",
				"value": i * 3.14159,
				"active": ( i mod 3 ) == 0,
				"category": [ "cat-a", "cat-b" ][ ( i mod 2 ) + 1 ]
			} );
		}
		application.stupidBig = serializeJson( stupidBigArr );

		systemOutput(
			"JSON bench seeded — "
			& "single: 4, flat: 2, medium: 3, mixed: 1, strings: 1, signs: 1, JSON5: 4, "
			& "big: " & numberFormat( len( application.big ) / 1024, "0.0" ) & "KB, "
			& "stupidBig: " & numberFormat( len( application.stupidBig ) / 1024, "0.0" ) & "KB"
			, true
		);
	}

}
