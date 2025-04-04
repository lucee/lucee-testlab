component extends="org.lucee.cfml.test.LuceeTestCase" labels="axis" {

	variables.localhost="http://127.0.0.1:8888";

	function run( testResults , testBox ) {
		describe( title="Lucee webservice / axis tests", body=function() {

			it(title="extensionInfo()", body = function( currentSpec ) {
				systemOutput("", true);
				systemOutput("extensionInfo(axis)", true);
				var info = ExtensionInfo( "DF28D0A4-6748-44B9-A2FDC12E4E2E4D38" );
				for (var i in info)
					systemOutput( i & ": " & info[ i ].toJson() , true );
				systemOutput("", true);
			});

			it(title="test wsdl", body = function( currentSpec ) {
				http url="#localhost#/ws.cfc?wsdl" result="local.result";
				var wsdl = result.filecontent ?: "";
				expect( isXml( wsdl ) ).toBeTrue();
			});

			it(title="test method", body = function( currentSpec ) {
				invoke webservice="#localhost#/ws.cfc?wsdl" method="hello" returnvariable="local.result";
				expect( trim(result) ).toBe("lucee-axis-hello");
			});
	
		});
	}
}