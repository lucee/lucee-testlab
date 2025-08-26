component extends="org.lucee.cfml.test.LuceeTestCase" labels="rest" {

	variables.localhost="http://127.0.0.1:8888";

	function beforeAll(){
		dumpRestConfig();
		var restPath = expandPath( getDirectoryFromPath(getCurrentTemplatePath()) & "../express-tests/simpleRest") & "/";
		RestInitApplication( restPath, '/simpleRestInit', true, "admin" );
		dumpRestConfig();
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
				http url="#localhost#/rest/simpleRestInit/simpleRest/info" result="local.result";
				systemOutput( "", true );
				systemOutput( result.filecontent, true ); // returns the path
				if (result.error) throw "Error: #result.filecontent#";
			});

		});
	}

	private function dumpRestConfig(){
		var cfconfig = DeSerializeJson(fileRead( expandPath('{lucee-config}.CFConfig.json') ) );
		systemOutput( "---------------cfconfig------------", true );
		systemOutput( serializeJson( var=cfconfig.rest, compact=false ), true );
	}
}