component extends="org.lucee.cfml.test.LuceeTestCase" labels="rest" {

	variables.localhost="http://127.0.0.1:8888";

	function beforeAll(){
		cfadmin(action="updateRestMapping",
            type="server",
            password="admin",
            virtual="/simpleRest",
            physical=expandPath("../express-tests/simpleRest"),
            default="false"
		);
	}

	function run( testResults , testBox ) {
		describe( title="Lucee Simple REST tests", body=function() {

			it(title="test REST List services", body = function( currentSpec ) {
				http url="#localhost#/rest/" result="local.result";
				systemOutput( "", true );
				systemOutput( result.filecontent, true );
				expect( result.filecontent ).toInclude( "Available sevice mappings are:" );
			});

			it(title="simple rest info", body = function( currentSpec ) {
				http url="#localhost#/rest/simpleRest/info" result="local.result";
				systemOutput( "", true );
				systemOutput( result.filecontent, true ); // returns the path
			});

		});
	}
}