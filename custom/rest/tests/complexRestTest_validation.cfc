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

		describe( title="Complex REST Tests - Parameter Type Validation", body=function() {

			it(title="GET /api/products/abc123def/reviews?page=1&limit=5&rating=3 - Alphanumeric path parameter", body = function( currentSpec ) {
				http url="#localhost#/rest/#variables.restMapping#/abc123def/reviews?page=1&limit=5&rating=3" result="local.result";
				systemOutput( "", true );
				systemOutput( "Test: Alphanumeric path parameter with numeric URL parameters", true );
				systemOutput( result.filecontent, true );
				debug( result.filecontent );
				if ( result.error ) throw "Error: #result.filecontent#";
				
				var response = deserializeJSON( result.filecontent );
				expect( response ).toHaveKey( "method" );
				expect( response.method ).toBe( "getProductReviews" );
				expect( response.productID ).toBe( "abc123def" );
				expect( response.pagination.page ).toBe( 1 );
				expect( response.pagination.limit ).toBe( 5 );
				expect( response.filters.rating ).toBe( 3 );
			});

			it(title="GET /api/products/search?sortBy=price&category=books - String parameters with various values", body = function( currentSpec ) {
				http url="#localhost#/rest/#variables.restMapping#/search?sortBy=price&category=books" result="local.result";
				systemOutput( "", true );
				systemOutput( "Test: String parameters with different sort options", true );
				systemOutput( result.filecontent, true );
				debug( result.filecontent );
				if ( result.error ) throw "Error: #result.filecontent#";
				
				var response = deserializeJSON( result.filecontent );
				expect( response ).toHaveKey( "method" );
				expect( response.method ).toBe( "searchProducts" );
				expect( response ).toHaveKey( "filters" );
				expect( response.filters.sortBy ).toBe( "price" );
				expect( response.filters.category ).toBe( "books" );
			});

			it(title="GET /api/products/analytics?startDate=2024-01-01&endDate=2024-01-31&format=csv - Date format validation", body = function( currentSpec ) {
				http url="#localhost#/rest/#variables.restMapping#/analytics?startDate=2024-01-01&endDate=2024-01-31&format=csv" result="local.result";
				systemOutput( "", true );
				systemOutput( "Test: Date format parameters with CSV format", true );
				systemOutput( result.filecontent, true );
				debug( result.filecontent );
				if ( result.error ) throw "Error: #result.filecontent#";
				
				var response = deserializeJSON( result.filecontent );
				expect( response ).toHaveKey( "method" );
				expect( response.method ).toBe( "getProductAnalytics" );
				expect( response ).toHaveKey( "dateRange" );
				expect( response.dateRange.start ).toBe( "2024-01-01" );
				expect( response.dateRange.end ).toBe( "2024-01-31" );
				expect( response.options.format ).toBe( "csv" );
			});

			it(title="GET /api/products/getProductsByCategory?category=Home%20%26%20Garden&active=1 - Boolean parameter as numeric", body = function( currentSpec ) {
				http url="#localhost#/rest/#variables.restMapping#/getProductsByCategory?category=Home%20%26%20Garden&active=1" result="local.result";
				systemOutput( "", true );
				systemOutput( "Test: Boolean parameter passed as numeric 1", true );
				systemOutput( result.filecontent, true );
				debug( result.filecontent );
				if ( result.error ) throw "Error: #result.filecontent#";
				
				var response = deserializeJSON( result.filecontent );
				expect( response ).toHaveKey( "method" );
				expect( response.method ).toBe( "getProductsByCategory" );
				expect( response ).toHaveKey( "category" );
				expect( response.category ).toBe( "Home & Garden" );
				expect( response.activeOnly ).toBe( true );
			});

			it(title="GET /api/products/getProductsByCategory?category=Sports&active=0 - Boolean parameter as numeric zero", body = function( currentSpec ) {
				http url="#localhost#/rest/#variables.restMapping#/getProductsByCategory?category=Sports&active=0" result="local.result";
				systemOutput( "", true );
				systemOutput( "Test: Boolean parameter passed as numeric 0", true );
				systemOutput( result.filecontent, true );
				debug( result.filecontent );
				if ( result.error ) throw "Error: #result.filecontent#";
				
				var response = deserializeJSON( result.filecontent );
				expect( response ).toHaveKey( "method" );
				expect( response.method ).toBe( "getProductsByCategory" );
				expect( response ).toHaveKey( "category" );
				expect( response.category ).toBe( "Sports" );
				expect( response.activeOnly ).toBe( false );
			});

		});
	}

}