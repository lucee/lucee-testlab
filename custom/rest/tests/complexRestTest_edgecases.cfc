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

		describe( title="Complex REST Tests - Edge Cases and Error Scenarios", body=function() {

			it(title="GET /api/products/special-chars-123 - Path parameter with special characters", body = function( currentSpec ) {
				http url="#localhost#/rest/#variables.restMapping#/special-chars-123" result="local.result";
				systemOutput( "", true );
				systemOutput( "Test: Path parameter with special characters", true );
				systemOutput( result.filecontent, true );
				debug( result.filecontent );
				if ( result.error ) throw "Error: #result.filecontent#";
				
				var response = deserializeJSON( result.filecontent );
				expect( response ).toHaveKey( "productID" );
				expect( response.productID ).toBe( "special-chars-123" );
				expect( response.method ).toBe( "getProduct" );
			});

			it(title="GET /api/products/search?minPrice=50.99&maxPrice=199.99 - Decimal URL parameters", body = function( currentSpec ) {
				http url="#localhost#/rest/#variables.restMapping#/search?minPrice=50.99&maxPrice=199.99" result="local.result";
				systemOutput( "", true );
				systemOutput( "Test: Search with decimal price parameters", true );
				systemOutput( result.filecontent, true );
				debug( result.filecontent );
				if ( result.error ) throw "Error: #result.filecontent#";
				
				var response = deserializeJSON( result.filecontent );
				expect( response ).toHaveKey( "filters" );
				expect( response.filters.minPrice ).toBe( 50.99 );
				expect( response.filters.maxPrice ).toBe( 199.99 );
				expect( response.method ).toBe( "searchProducts" );
			});

			it(title="GET /api/products/search?category=Gaming%20%26%20Electronics - URL-encoded parameters", body = function( currentSpec ) {
				http url="#localhost#/rest/#variables.restMapping#/search?category=Gaming%20%26%20Electronics" result="local.result";
				systemOutput( "", true );
				systemOutput( "Test: URL-encoded category parameter", true );
				systemOutput( result.filecontent, true );
				debug( result.filecontent );
				if ( result.error ) throw "Error: #result.filecontent#";
				
				var response = deserializeJSON( result.filecontent );
				expect( response ).toHaveKey( "filters" );
				expect( response.filters.category ).toBe( "Gaming & Electronics" );
				expect( response.method ).toBe( "searchProducts" );
			});

			it(title="GET /api/products/0/reviews - Zero as path parameter", body = function( currentSpec ) {
				http url="#localhost#/rest/#variables.restMapping#/0/reviews" result="local.result";
				systemOutput( "", true );
				systemOutput( "Test: Zero as path parameter", true );
				systemOutput( result.filecontent, true );
				debug( result.filecontent );
				if ( result.error ) throw "Error: #result.filecontent#";
				
				var response = deserializeJSON( result.filecontent );
				expect( response ).toHaveKey( "productID" );
				expect( response.productID ).toBe( "0" );
				expect( response.method ).toBe( "getProductReviews" );
			});

			it(title="GET /api/products/search?minPrice=-10&maxPrice=0 - Negative and zero numeric parameters", body = function( currentSpec ) {
				http url="#localhost#/rest/#variables.restMapping#/search?minPrice=-10&maxPrice=0" result="local.result";
				systemOutput( "", true );
				systemOutput( "Test: Negative and zero numeric parameters", true );
				systemOutput( result.filecontent, true );
				debug( result.filecontent );
				if ( result.error ) throw "Error: #result.filecontent#";
				
				var response = deserializeJSON( result.filecontent );
				expect( response ).toHaveKey( "filters" );
				expect( response.filters.minPrice ).toBe( -10 );
				expect( response.filters.maxPrice ).toBe( 0 );
				expect( response.method ).toBe( "searchProducts" );
			});

			it(title="GET /api/products/getProductsByCategory?category= - Empty string parameter", body = function( currentSpec ) {
				http url="#localhost#/rest/#variables.restMapping#/getProductsByCategory?category=" result="local.result";
				systemOutput( "", true );
				systemOutput( "Test: Empty string category parameter", true );
				systemOutput( result.filecontent, true );
				debug( result.filecontent );
				if ( result.error ) throw "Error: #result.filecontent#";
				
				var response = deserializeJSON( result.filecontent );
				expect( response ).toHaveKey( "category" );
				expect( response.category ).toBe( "" );
				expect( response.method ).toBe( "getProductsByCategory" );
			});

		});
	}

}