component extends="org.lucee.cfml.test.LuceeTestCase" labels="rest,LDEV-6306" {

	variables.localhost = "http://127.0.0.1:8888";

	// Cases 1-3 use this mapping (no ambiguous routes inside).
	variables.mainMapping = "restPrefixOverlap";
	// Case 4 uses a separate mapping because identical restpath would block
	// app init on JAX-RS-compliant engines (ACF) -- splitting keeps the rest
	// of the matrix testable.
	variables.dupMapping = "restDuplicates";

	function beforeAll(){
		systemOutput( "---------remote express server---------", true );

		// Order matters: restPrefixOverlap setup clears all existing mappings,
		// then adds itself. restDuplicates setup adds without clearing.
		http url="#localhost#/restTest/express-tests/restPrefixOverlap/setupRestPrefixOverlap.cfm" result="local.r1";
		systemOutput( r1.filecontent, true );
		if ( r1.error ) throw "setupRestPrefixOverlap failed: #r1.filecontent#";

		http url="#localhost#/restTest/express-tests/restDuplicates/setupRestDuplicates.cfm" result="local.r2";
		systemOutput( r2.filecontent, true );
		if ( r2.error ) throw "setupRestDuplicates failed: #r2.filecontent#";
	}

	private struct function callRest( required string mapping, required string path, string method="GET" ){
		http url="#localhost#/rest/#arguments.mapping#/#arguments.path#" method="#arguments.method#" result="local.result";
		systemOutput( "", true );
		systemOutput( "#arguments.method# /#arguments.mapping#/#arguments.path# -> #result.status_code#", true );
		systemOutput( result.filecontent, true );
		debug( result.filecontent );
		return result;
	}

	function run( testResults, testBox ) {

		describe( title="LDEV-6306 baseline -- single CFC matches", body=function() {

			it( title="GET /api/ping -- prefixShort handles its own path", body=function() {
				var r = callRest( variables.mainMapping, "api/ping" );
				expect( r.status_code ).toBe( 200 );
				var body = deserializeJSON( r.filecontent );
				expect( body.handler ).toBe( "prefixShort" );
			});

			it( title="GET /users/123 -- pathvar handles non-literal segment", body=function() {
				var r = callRest( variables.mainMapping, "users/123" );
				expect( r.status_code ).toBe( 200 );
				var body = deserializeJSON( r.filecontent );
				expect( body.handler ).toBe( "pathvar" );
				expect( body.id ).toBe( "123" );
			});

			it( title="GET /orders -- methodGet handles its own path", body=function() {
				var r = callRest( variables.mainMapping, "orders" );
				expect( r.status_code ).toBe( 200 );
				var body = deserializeJSON( r.filecontent );
				expect( body.handler ).toBe( "methodGet" );
			});
		});

		// NOTE for cases 1, 2, 3, 4:
		// These tests assert the post-fix correct behaviour and currently FAIL
		// on Lucee 7.0.4 -- the failures ARE the bug evidence. ACF passes them.
		// The current "passing" of cases 1+2 in some Lucee builds is alphabetical
		// luck -- proven by the rest-testlab filename-flip probe at
		// D:\testbeds\rest-testlab\probe.sh (rename z-prefix the more-specific CFC
		// and watch case 1+2 flip to 404 / wrong handler).

		describe( title="LDEV-6306 case 1 -- prefix collision (/api vs /api/v1)", body=function() {

			it( title="GET /api/v1/ping -- longest prefix should win (prefixLong)", body=function() {
				var r = callRest( variables.mainMapping, "api/v1/ping" );
				expect( r.status_code ).toBe( 200 );
				var body = deserializeJSON( r.filecontent );
				expect( body.handler ).toBe( "prefixLong" );
			});
		});

		describe( title="LDEV-6306 case 2 -- path-param vs literal (/users/{id} vs /users/me)", body=function() {

			it( title="GET /users/me -- literal should beat path variable", body=function() {
				var r = callRest( variables.mainMapping, "users/me" );
				expect( r.status_code ).toBe( 200 );
				var body = deserializeJSON( r.filecontent );
				expect( body.handler ).toBe( "literal" );
			});
		});

		describe( title="LDEV-6306 case 3 -- method spillover (GET /orders vs POST /orders/items)", body=function() {

			it( title="POST /orders/items -- should fall through to methodPost CFC", body=function() {
				var r = callRest( variables.mainMapping, "orders/items", "POST" );
				expect( r.status_code ).toBe( 200 );
				var body = deserializeJSON( r.filecontent );
				expect( body.handler ).toBe( "methodPost" );
			});
		});

		describe( title="LDEV-6306 case 4 -- identical restpath on two CFCs (/dup)", body=function() {

			// Post-fix expectation: registering two CFCs with restpath="/dup" is
			// a hard error at restInitApplication time (matches ACF / JAX-RS spec).
			// Lucee today silently shadows -- the second CFC's functions are
			// unreachable. Once the registration error lands, this whole describe
			// block becomes "expect setupRestDuplicates to throw" instead.
			//
			// Until then, these tests assert that BOTH dup CFCs' unique functions
			// are reachable -- which can never be true under the current
			// shadowing behaviour, so they fail.

			it( title="GET /dup/onlyA -- function only on dupA must be reachable", body=function() {
				var r = callRest( variables.dupMapping, "dup/onlyA" );
				expect( r.status_code ).toBe( 200 );
				var body = deserializeJSON( r.filecontent );
				expect( body.handler ).toBe( "dupA" );
			});

			it( title="GET /dup/onlyB -- function only on dupB must be reachable", body=function() {
				var r = callRest( variables.dupMapping, "dup/onlyB" );
				expect( r.status_code ).toBe( 200 );
				var body = deserializeJSON( r.filecontent );
				expect( body.handler ).toBe( "dupB" );
			});
		});
	}
}
