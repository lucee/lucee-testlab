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
		describe( title="Complex REST Tests - BASIC tests", body=function() {

			it(title="test REST List services", body = function( currentSpec ) {
				http url="#localhost#/rest/" result="local.result";
				systemOutput( "", true );
				systemOutput( result.filecontent, true );
				debug( result.filecontent );
				expect( result.filecontent ).toInclude( "Available sevice mappings are:" );
			});

			it(title="GET /hello - rest method with rest-path", body = function( currentSpec ) {
				http url="#localhost#/rest/#variables.restMapping#/function-with-rest-path/hello" result="local.result";
				systemOutput( "", true );
				systemOutput( result.filecontent, true );
				debug( result.filecontent );
				if ( result.error ) throw "Error: #result.filecontent#";
				expect( result.filecontent ).toInclude( "hello-method-withrestpath" );
			});
		});

		describe( title="Complex REST Tests - Product API", body=function() {

			it(title="POST /api/products - POST with empty restPath", body = function( currentSpec ) {
				http url="#localhost#/rest/#variables.restMapping#" method="POST" result="local.result";
				systemOutput( "", true );
				systemOutput( "Test: POST product with empty restPath", true );
				systemOutput( result.filecontent, true );
				debug( result.filecontent );
				if ( result.error ) throw "Error: #result.filecontent#";
				
				var response = deserializeJSON( result.filecontent );
				expect( response ).toHaveKey( "method" );
				expect( response.method ).toBe( "addProduct" );
				expect( response ).toHaveKey( "message" );
				expect( response.message ).toBe( "Product added" );
			});

			it(title="GET /api/products/123 - Path parameter test", body = function( currentSpec ) {
				http url="#localhost#/rest/#variables.restMapping#/123" result="local.result";
				systemOutput( "", true );
				systemOutput( "Test: GET single product with path parameter", true );
				systemOutput( result.filecontent, true );
				debug( result.filecontent );
				if ( result.error ) throw "Error: #result.filecontent#";
				
				var response = deserializeJSON( result.filecontent );
				expect( response ).toHaveKey( "method" );
				expect( response.method ).toBe( "getProduct" );
				expect( response ).toHaveKey( "message" );
				expect( response.message ).toBe( "Single product retrieved" );
				expect( response.productID ).toBe( "123" );
				
			});

			it(title="GET /api/products/search - URL parameters with defaults", body = function( currentSpec ) {
				http url="#localhost#/rest/#variables.restMapping#/search" result="local.result";
				systemOutput( "", true );
				systemOutput( "Test: Search products with default URL parameters", true );
				systemOutput( result.filecontent, true );
				debug( result.filecontent );
				if ( result.error ) throw "Error: #result.filecontent#";
				
				var response = deserializeJSON( result.filecontent );
				expect( response ).toHaveKey( "method" );
				expect( response.method ).toBe( "searchProducts" );
				expect( response ).toHaveKey( "message" );
				expect( response.message ).toBe( "Product search completed" );
				expect( response.filters.category ).toBe( "" );
				expect( response.filters.minPrice ).toBe( 0 );
				expect( response.filters.maxPrice ).toBe( 999999 );
				expect( response.filters.sortBy ).toBe( "name" );
			});

			it(title="GET /api/products/search?category=electronics&minPrice=100&maxPrice=500 - URL parameters with values", body = function( currentSpec ) {
				http url="#localhost#/rest/#variables.restMapping#/search?category=electronics&minPrice=100&maxPrice=500&sortBy=price" result="local.result";
				systemOutput( "", true );
				systemOutput( "Test: Search products with specific URL parameters", true );
				systemOutput( result.filecontent, true );
				debug( result.filecontent );
				if ( result.error ) throw "Error: #result.filecontent#";
				
				var response = deserializeJSON( result.filecontent );
				expect( response ).toHaveKey( "method" );
				expect( response.method ).toBe( "searchProducts" );
				expect( response ).toHaveKey( "message" );
				expect( response.message ).toBe( "Product search completed" );
				expect( response.filters.category ).toBe( "electronics" );
				expect( response.filters.minPrice ).toBe( 100 );
				expect( response.filters.maxPrice ).toBe( 500 );
				expect( response.filters.sortBy ).toBe( "price" );
			});

			it(title="GET /api/products/456/reviews - Path + URL parameters with defaults", body = function( currentSpec ) {
				http url="#localhost#/rest/#variables.restMapping#/456/reviews" result="local.result";
				systemOutput( "", true );
				systemOutput( "Test: Get product reviews with path parameter and default URL parameters", true );
				systemOutput( result.filecontent, true );
				debug( result.filecontent );
				if ( result.error ) throw "Error: #result.filecontent#";
				
				var response = deserializeJSON( result.filecontent );
				expect( response ).toHaveKey( "method" );
				expect( response.method ).toBe( "getProductReviews" );
				expect( response ).toHaveKey( "message" );
				expect( response.message ).toBe( "Product reviews retrieved" );
				expect( response.productID ).toBe( "456" );
				expect( response.pagination.page ).toBe( 1 );
				expect( response.pagination.limit ).toBe( 20 );
				expect( response.filters.rating ).toBe( 0 );
			});

			it(title="GET /api/products/789/reviews?page=2&limit=10&rating=4 - Path + URL parameters with values", body = function( currentSpec ) {
				http url="#localhost#/rest/#variables.restMapping#/789/reviews?page=2&limit=10&rating=4" result="local.result";
				systemOutput( "", true );
				systemOutput( "Test: Get product reviews with path and URL parameters", true );
				systemOutput( result.filecontent, true );
				debug( result.filecontent );
				if ( result.error ) throw "Error: #result.filecontent#";
				
				var response = deserializeJSON( result.filecontent );
				expect( response ).toHaveKey( "method" );
				expect( response.method ).toBe( "getProductReviews" );
				expect( response ).toHaveKey( "message" );
				expect( response.message ).toBe( "Product reviews retrieved" );
				expect( response.productID ).toBe( "789" );
				expect( response.pagination.page ).toBe( 2 );
				expect( response.pagination.limit ).toBe( 10 );
				expect( response.filters.rating ).toBe( 4 );
			});
		
			it(title="PUT /api/products/999/status - PUT method with path parameter", body = function( currentSpec ) {
				http url="#localhost#/rest/#variables.restMapping#/999/status" method="PUT" result="local.result";
				systemOutput( "", true );
				systemOutput( "Test: Update product status with PUT method", true );
				systemOutput( result.filecontent, true );
				debug( result.filecontent );
				if ( result.error ) throw "Error: #result.filecontent#";
				
				var response = deserializeJSON( result.filecontent );
				expect( response ).toHaveKey( "method" );
				expect( response.method ).toBe( "updateProductStatus" );
				expect( response ).toHaveKey( "message" );
				expect( response.message ).toBe( "Product status updated" );
				expect( response.productID ).toBe( "999" );
			});

			it(title="GET /api/products/analytics - Analytics with minimal required parameters", body = function( currentSpec ) {
				http url="#localhost#/rest/#variables.restMapping#/analytics?startDate=2024-01-01&endDate=2024-12-31" result="local.result";
				systemOutput( "", true );
				systemOutput( "Test: Get analytics with minimal parameters", true );
				systemOutput( result.filecontent, true );
				debug( result.filecontent );
				if ( result.error ) throw "Error: #result.filecontent#";
				
				var response = deserializeJSON( result.filecontent );
				expect( response ).toHaveKey( "method" );
				expect( response.method ).toBe( "getProductAnalytics" );
				expect( response ).toHaveKey( "message" );
				expect( response.message ).toBe( "Product analytics retrieved" );
				expect( response.dateRange.start ).toBe( "2024-01-01" );
				expect( response.dateRange.end ).toBe( "2024-12-31" );
				expect( response.options.format ).toBe( "json" );
				expect( response.options.includeDeleted ).toBe( false );
			});

			it(title="GET /api/products/analytics - Analytics with all parameters", body = function( currentSpec ) {
				http url="#localhost#/rest/#variables.restMapping#/analytics?startDate=2023-06-01&endDate=2023-12-31&format=xml&includeDeleted=true" result="local.result";
				systemOutput( "", true );
				systemOutput( "Test: Get analytics with all parameters specified", true );
				systemOutput( result.filecontent, true );
				debug( result.filecontent );
				if ( result.error ) throw "Error: #result.filecontent#";
				
				var response = deserializeJSON( result.filecontent );
				expect( response ).toHaveKey( "method" );
				expect( response.method ).toBe( "getProductAnalytics" );
				expect( response ).toHaveKey( "message" );
				expect( response.message ).toBe( "Product analytics retrieved" );
				expect( response.dateRange.start ).toBe( "2023-06-01" );
				expect( response.dateRange.end ).toBe( "2023-12-31" );
				expect( response.options.format ).toBe( "xml" );
				expect( response.options.includeDeleted ).toBe( true );
			});

		});
	}

}