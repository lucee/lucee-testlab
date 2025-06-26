component extends="org.lucee.cfml.test.LuceeTestCase" labels="rest" {

	variables.localhost="http://127.0.0.1:8888";

	function run( testResults , testBox ) {
		describe( title="Lucee REST tests", body=function() {

			it(title="test REST List services", body = function( currentSpec ) {
				http url="#localhost#/rest/" result="local.result";
				systemOutput( "", true );
				systemOutput( result.filecontent, true );
				expect( result.filecontent ).toInclude( "Available sevice mappings are:" );
			});

		});
	}
}