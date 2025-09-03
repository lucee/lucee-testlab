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
		describe( title="Complex REST Tests - Product API", body=function() {

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

			it(title="GET /api/products/getProducts - Simple GET method using function name", body = function( currentSpec ) {
				http url="#localhost#/rest/#variables.restMapping#/getProducts" result="local.result";
				systemOutput( "", true );
				systemOutput( "Test: GET products using function name", true );
				systemOutput( result.filecontent, true );
				debug( result.filecontent );
				if ( result.error ) throw "Error: #result.filecontent#";
				
				var response = deserializeJSON( result.filecontent );
				expect( response.message ).toBe( "All products retrieved" );
				expect( response.method ).toBe( "getProducts" );
			});

			it(title="POST /api/products - POST with empty restPath", body = function( currentSpec ) {
				http url="#localhost#/rest/#variables.restMapping#" method="POST" result="local.result";
				systemOutput( "", true );
				systemOutput( "Test: POST product with empty restPath", true );
				systemOutput( result.filecontent, true );
				debug( result.filecontent );
				if ( result.error ) throw "Error: #result.filecontent#";
				
				var response = deserializeJSON( result.filecontent );
				expect( response.message ).toBe( "Product added" );
				expect( response.method ).toBe( "addProduct" );
			});

			it(title="GET /api/products/123 - Path parameter test", body = function( currentSpec ) {
				http url="#localhost#/rest/#variables.restMapping#/123" result="local.result";
				systemOutput( "", true );
				systemOutput( "Test: GET single product with path parameter", true );
				systemOutput( result.filecontent, true );
				debug( result.filecontent );
				if ( result.error ) throw "Error: #result.filecontent#";
				
				var response = deserializeJSON( result.filecontent );
				expect( response.message ).toBe( "Single product retrieved" );
				expect( response.productID ).toBe( "123" );
				expect( response.method ).toBe( "getProduct" );
			});

			it(title="GET /api/products/search - URL parameters with defaults", body = function( currentSpec ) {
				http url="#localhost#/rest/#variables.restMapping#/search" result="local.result";
				systemOutput( "", true );
				systemOutput( "Test: Search products with default URL parameters", true );
				systemOutput( result.filecontent, true );
				debug( result.filecontent );
				if ( result.error ) throw "Error: #result.filecontent#";
				
				var response = deserializeJSON( result.filecontent );
				expect( response.message ).toBe( "Product search completed" );
				expect( response.filters.category ).toBe( "" );
				expect( response.filters.minPrice ).toBe( 0 );
				expect( response.filters.maxPrice ).toBe( 999999 );
				expect( response.filters.sortBy ).toBe( "name" );
				expect( response.method ).toBe( "searchProducts" );
			});

			it(title="GET /api/products/search?category=electronics&minPrice=100&maxPrice=500 - URL parameters with values", body = function( currentSpec ) {
				http url="#localhost#/rest/#variables.restMapping#/search?category=electronics&minPrice=100&maxPrice=500&sortBy=price" result="local.result";
				systemOutput( "", true );
				systemOutput( "Test: Search products with specific URL parameters", true );
				systemOutput( result.filecontent, true );
				debug( result.filecontent );
				if ( result.error ) throw "Error: #result.filecontent#";
				
				var response = deserializeJSON( result.filecontent );
				expect( response.message ).toBe( "Product search completed" );
				expect( response.filters.category ).toBe( "electronics" );
				expect( response.filters.minPrice ).toBe( 100 );
				expect( response.filters.maxPrice ).toBe( 500 );
				expect( response.filters.sortBy ).toBe( "price" );
				expect( response.method ).toBe( "searchProducts" );
			});

			it(title="GET /api/products/456/reviews - Path + URL parameters with defaults", body = function( currentSpec ) {
				http url="#localhost#/rest/#variables.restMapping#/456/reviews" result="local.result";
				systemOutput( "", true );
				systemOutput( "Test: Get product reviews with path parameter and default URL parameters", true );
				systemOutput( result.filecontent, true );
				debug( result.filecontent );
				if ( result.error ) throw "Error: #result.filecontent#";
				
				var response = deserializeJSON( result.filecontent );
				expect( response.message ).toBe( "Product reviews retrieved" );
				expect( response.productID ).toBe( "456" );
				expect( response.pagination.page ).toBe( 1 );
				expect( response.pagination.limit ).toBe( 20 );
				expect( response.filters.rating ).toBe( 0 );
				expect( response.method ).toBe( "getProductReviews" );
			});

			it(title="GET /api/products/789/reviews?page=2&limit=10&rating=4 - Path + URL parameters with values", body = function( currentSpec ) {
				http url="#localhost#/rest/#variables.restMapping#/789/reviews?page=2&limit=10&rating=4" result="local.result";
				systemOutput( "", true );
				systemOutput( "Test: Get product reviews with path and URL parameters", true );
				systemOutput( result.filecontent, true );
				debug( result.filecontent );
				if ( result.error ) throw "Error: #result.filecontent#";
				
				var response = deserializeJSON( result.filecontent );
				expect( response.message ).toBe( "Product reviews retrieved" );
				expect( response.productID ).toBe( "789" );
				expect( response.pagination.page ).toBe( 2 );
				expect( response.pagination.limit ).toBe( 10 );
				expect( response.filters.rating ).toBe( 4 );
				expect( response.method ).toBe( "getProductReviews" );
			});

			it(title="GET /api/products/getProductsByCategory?category=books - Function name with required URL parameter", body = function( currentSpec ) {
				http url="#localhost#/rest/#variables.restMapping#/getProductsByCategory?category=books" result="local.result";
				systemOutput( "", true );
				systemOutput( "Test: Get products by category with required parameter", true );
				systemOutput( result.filecontent, true );
				debug( result.filecontent );
				if ( result.error ) throw "Error: #result.filecontent#";
				
				var response = deserializeJSON( result.filecontent );
				expect( response.message ).toBe( "Products retrieved by category" );
				expect( response.category ).toBe( "books" );
				expect( response.activeOnly ).toBe( true );
				expect( response.method ).toBe( "getProductsByCategory" );
			});

			it(title="GET /api/products/getProductsByCategory?category=electronics&active=false - Function name with multiple URL parameters", body = function( currentSpec ) {
				http url="#localhost#/rest/#variables.restMapping#/getProductsByCategory?category=electronics&active=false" result="local.result";
				systemOutput( "", true );
				systemOutput( "Test: Get products by category with multiple parameters", true );
				systemOutput( result.filecontent, true );
				debug( result.filecontent );
				if ( result.error ) throw "Error: #result.filecontent#";
				
				var response = deserializeJSON( result.filecontent );
				expect( response.message ).toBe( "Products retrieved by category" );
				expect( response.category ).toBe( "electronics" );
				expect( response.activeOnly ).toBe( false );
				expect( response.method ).toBe( "getProductsByCategory" );
			});

			it(title="PUT /api/products/999/status - PUT method with path parameter", body = function( currentSpec ) {
				http url="#localhost#/rest/#variables.restMapping#/999/status" method="PUT" result="local.result";
				systemOutput( "", true );
				systemOutput( "Test: Update product status with PUT method", true );
				systemOutput( result.filecontent, true );
				debug( result.filecontent );
				if ( result.error ) throw "Error: #result.filecontent#";
				
				var response = deserializeJSON( result.filecontent );
				expect( response.message ).toBe( "Product status updated" );
				expect( response.productID ).toBe( "999" );
				expect( response.method ).toBe( "updateProductStatus" );
			});

			it(title="GET /api/products/analytics - Analytics with minimal required parameters", body = function( currentSpec ) {
				http url="#localhost#/rest/#variables.restMapping#/analytics?startDate=2024-01-01&endDate=2024-12-31" result="local.result";
				systemOutput( "", true );
				systemOutput( "Test: Get analytics with minimal parameters", true );
				systemOutput( result.filecontent, true );
				debug( result.filecontent );
				if ( result.error ) throw "Error: #result.filecontent#";
				
				var response = deserializeJSON( result.filecontent );
				expect( response.message ).toBe( "Product analytics retrieved" );
				expect( response.dateRange.start ).toBe( "2024-01-01" );
				expect( response.dateRange.end ).toBe( "2024-12-31" );
				expect( response.options.format ).toBe( "json" );
				expect( response.options.includeDeleted ).toBe( false );
				expect( response.method ).toBe( "getProductAnalytics" );
			});

			it(title="GET /api/products/analytics - Analytics with all parameters", body = function( currentSpec ) {
				http url="#localhost#/rest/#variables.restMapping#/analytics?startDate=2023-06-01&endDate=2023-12-31&format=xml&includeDeleted=true" result="local.result";
				systemOutput( "", true );
				systemOutput( "Test: Get analytics with all parameters specified", true );
				systemOutput( result.filecontent, true );
				debug( result.filecontent );
				if ( result.error ) throw "Error: #result.filecontent#";
				
				var response = deserializeJSON( result.filecontent );
				expect( response.message ).toBe( "Product analytics retrieved" );
				expect( response.dateRange.start ).toBe( "2023-06-01" );
				expect( response.dateRange.end ).toBe( "2023-12-31" );
				expect( response.options.format ).toBe( "xml" );
				expect( response.options.includeDeleted ).toBe( true );
				expect( response.method ).toBe( "getProductAnalytics" );
			});

		});

		describe( title="Complex REST Tests - Edge Cases and Error Scenarios", body=function() {

			it(title="GET /api/products/special-chars-123 - Path parameter with special characters", body = function( currentSpec ) {
				http url="#localhost#/rest/#variables.restMapping#/special-chars-123" result="local.result";
				systemOutput( "", true );
				systemOutput( "Test: Path parameter with special characters", true );
				systemOutput( result.filecontent, true );
				debug( result.filecontent );
				if ( result.error ) throw "Error: #result.filecontent#";
				
				var response = deserializeJSON( result.filecontent );
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
				expect( response.category ).toBe( "" );
				expect( response.method ).toBe( "getProductsByCategory" );
			});

		});

		describe( title="Complex REST Tests - Parameter Type Validation", body=function() {

			it(title="GET /api/products/abc123def/reviews?page=1&limit=5&rating=3 - Alphanumeric path parameter", body = function( currentSpec ) {
				http url="#localhost#/rest/#variables.restMapping#/abc123def/reviews?page=1&limit=5&rating=3" result="local.result";
				systemOutput( "", true );
				systemOutput( "Test: Alphanumeric path parameter with numeric URL parameters", true );
				systemOutput( result.filecontent, true );
				debug( result.filecontent );
				if ( result.error ) throw "Error: #result.filecontent#";
				
				var response = deserializeJSON( result.filecontent );
				expect( response.productID ).toBe( "abc123def" );
				expect( response.pagination.page ).toBe( 1 );
				expect( response.pagination.limit ).toBe( 5 );
				expect( response.filters.rating ).toBe( 3 );
				expect( response.method ).toBe( "getProductReviews" );
			});

			it(title="GET /api/products/search?sortBy=price&category=books - String parameters with various values", body = function( currentSpec ) {
				http url="#localhost#/rest/#variables.restMapping#/search?sortBy=price&category=books" result="local.result";
				systemOutput( "", true );
				systemOutput( "Test: String parameters with different sort options", true );
				systemOutput( result.filecontent, true );
				debug( result.filecontent );
				if ( result.error ) throw "Error: #result.filecontent#";
				
				var response = deserializeJSON( result.filecontent );
				expect( response.filters.sortBy ).toBe( "price" );
				expect( response.filters.category ).toBe( "books" );
				expect( response.method ).toBe( "searchProducts" );
			});

			it(title="GET /api/products/analytics?startDate=2024-01-01&endDate=2024-01-31&format=csv - Date format validation", body = function( currentSpec ) {
				http url="#localhost#/rest/#variables.restMapping#/analytics?startDate=2024-01-01&endDate=2024-01-31&format=csv" result="local.result";
				systemOutput( "", true );
				systemOutput( "Test: Date format parameters with CSV format", true );
				systemOutput( result.filecontent, true );
				debug( result.filecontent );
				if ( result.error ) throw "Error: #result.filecontent#";
				
				var response = deserializeJSON( result.filecontent );
				expect( response.dateRange.start ).toBe( "2024-01-01" );
				expect( response.dateRange.end ).toBe( "2024-01-31" );
				expect( response.options.format ).toBe( "csv" );
				expect( response.method ).toBe( "getProductAnalytics" );
			});

			it(title="GET /api/products/getProductsByCategory?category=Home%20%26%20Garden&active=1 - Boolean parameter as numeric", body = function( currentSpec ) {
				http url="#localhost#/rest/#variables.restMapping#/getProductsByCategory?category=Home%20%26%20Garden&active=1" result="local.result";
				systemOutput( "", true );
				systemOutput( "Test: Boolean parameter passed as numeric 1", true );
				systemOutput( result.filecontent, true );
				debug( result.filecontent );
				if ( result.error ) throw "Error: #result.filecontent#";
				
				var response = deserializeJSON( result.filecontent );
				expect( response.category ).toBe( "Home & Garden" );
				expect( response.activeOnly ).toBe( true );
				expect( response.method ).toBe( "getProductsByCategory" );
			});

			it(title="GET /api/products/getProductsByCategory?category=Sports&active=0 - Boolean parameter as numeric zero", body = function( currentSpec ) {
				http url="#localhost#/rest/#variables.restMapping#/getProductsByCategory?category=Sports&active=0" result="local.result";
				systemOutput( "", true );
				systemOutput( "Test: Boolean parameter passed as numeric 0", true );
				systemOutput( result.filecontent, true );
				debug( result.filecontent );
				if ( result.error ) throw "Error: #result.filecontent#";
				
				var response = deserializeJSON( result.filecontent );
				expect( response.category ).toBe( "Sports" );
				expect( response.activeOnly ).toBe( false );
				expect( response.method ).toBe( "getProductsByCategory" );
			});

		});
	}

}