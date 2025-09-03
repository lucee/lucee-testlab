component extends="org.lucee.cfml.test.LuceeTestCase" labels="rest" {

	variables.localhost="http://127.0.0.1:8888";
	variables.restMapping = "complexRest/api/products";

	function beforeAll(){


		// NOTE this is running in script runner, not on the express server!
		/*
		var restPath = expandPath( getDirectoryFromPath(getCurrentTemplatePath()) & "../express-tests/complexRest") & "/";
	
		cfadmin(action="updateRestMapping",
			type="server",
			password="webweb",
			virtual="simpleRest",
			physical=restPath,
			default="false"
		);

		cfadmin(action="updateRestSettings",
				type="server",
				password="webweb",
				list="true"
		);
		systemOutput("---------local script runner---------", true);
		new "../express-tests/restUtils"().dumpRestConfig();
		*/
		systemOutput("---------remote express server---------", true);
		// this performs the same config on the express server
		http url="#localhost#/restTest/express-tests/complexRest/setupComplexRestTest.cfm" result="local.result";
		systemOutput( "", true );
		systemOutput( result.filecontent, true ); // returns the path
		debug( result.filecontent );
		if (result.error) throw "Error: #result.filecontent#";

	}

	function run( testResults , testBox ) {
		describe( title="LDEV-5795 Complex REST Tests - Product API - by function name", body=function() {

			it(title="GET /api/products/getProducts - Simple GET method using function name", body = function( currentSpec ) {
				http url="#localhost#/rest/#variables.restMapping#/getProducts" result="local.result";
				systemOutput( "", true );
				systemOutput( "Test: GET products using function name", true );
				systemOutput( result.filecontent, true );
				debug( result.filecontent );
				if ( result.error ) throw "Error: #result.filecontent#";
				
				var response = deserializeJSON( result.filecontent );
				expect( response ).toHaveKey( "method" );
				expect( response.method ).toBe( "getProducts" );
				expect( response ).toHaveKey( "message" );
				expect( response.message ).toBe( "All products retrieved" );
			});


			it(title="GET /api/products/getProductsByCategory?category=books - Function name with required URL parameter", body = function( currentSpec ) {
				http url="#localhost#/rest/#variables.restMapping#/getProductsByCategory?category=books" result="local.result";
				systemOutput( "", true );
				systemOutput( "Test: Get products by category with required parameter", true );
				systemOutput( result.filecontent, true );
				debug( result.filecontent );
				if ( result.error ) throw "Error: #result.filecontent#";
				
				var response = deserializeJSON( result.filecontent );
				expect( response ).toHaveKey( "method" );
				expect( response.method ).toBe( "getProductsByCategory" );
				expect( response ).toHaveKey( "message" );
				expect( response.message ).toBe( "Products retrieved by category" );
				expect( response.category ).toBe( "books" );
				expect( response.activeOnly ).toBe( true );
			});

			it(title="GET /api/products/getProductsByCategory?category=electronics&active=false - Function name with multiple URL parameters", body = function( currentSpec ) {
				http url="#localhost#/rest/#variables.restMapping#/getProductsByCategory?category=electronics&active=false" result="local.result";
				systemOutput( "", true );
				systemOutput( "Test: Get products by category with multiple parameters", true );
				systemOutput( result.filecontent, true );
				debug( result.filecontent );
				if ( result.error ) throw "Error: #result.filecontent#";
				
				var response = deserializeJSON( result.filecontent );
				expect( response ).toHaveKey( "method" );
				expect( response.method ).toBe( "getProductsByCategory" );
				expect( response ).toHaveKey( "message" );
				expect( response.message ).toBe( "Products retrieved by category" );
				expect( response.category ).toBe( "electronics" );
				expect( response.activeOnly ).toBe( false );
			});
		});
	}

}