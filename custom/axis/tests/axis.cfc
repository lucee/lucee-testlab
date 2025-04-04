component extends="org.lucee.cfml.test.LuceeTestCase" labels="axis" {

	variables.localhost="http://127.0.0.1:8888/";

	function run( testResults , testBox ) {
		describe( title="Lucee webservice axis tests",skip=Util::isAWSNotSupported(), body=function() {
			
			it(title="test wsdl", body = function( currentSpec ) {
				http url="#localhost#/ws.cfc?wsdl" result="local.result";
				var wdsl = result.filecontent;
				expect( isXml(wsdl ) ).toBeTrue();
			});

			it(title="test method", body = function( currentSpec ) {
				invoke webservice="#localhost#/ws.cfc?wsdl" method="hello" returnvariable="local.result";
				expect( trim(result) ).toBe("lucee-axis-hello");
			});
	
		});
	}
}