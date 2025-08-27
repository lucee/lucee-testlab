component extends="org.lucee.cfml.test.LuceeTestCase" labels="rest" {

	variables.localhost="http://127.0.0.1:8888";

	function beforeAll(){

		// NOTE this is running in script runner, not on the express server!
		/*
		var restPath = expandPath( getDirectoryFromPath(getCurrentTemplatePath()) & "../express-tests/simpleRest") & "/";
		RestInitApplication( restPath, '/simpleRestInit', true, "webweb" );

		systemOutput("---------local script runner---------", true);
		new "../express-tests/restUtils"().dumpRestConfig();
		*/
		systemOutput("---------remote express server---------", true);
		// this performs the same config on the express server
		http url="#localhost#/restTest/express-tests/simpleRest/setupSimpleRestTestInit.cfm" result="local.result";
		systemOutput( "", true );
		systemOutput( result.filecontent, true ); // returns the path
		debug( result.filecontent );
		if (result.error) throw "Error: #result.filecontent#";
		
	}

	function run( testResults , testBox ) {
		describe( title="Lucee Simple REST tests- RestInitApplication", body=function() {

			it(title="test REST List services", body = function( currentSpec ) {
				http url="#localhost#/rest/" result="local.result";
				systemOutput( "", true );
				systemOutput( result.filecontent, true );
				debug(result.filecontent );
				expect( result.filecontent ).toInclude( "Available sevice mappings are:" );
			});

			it(title="simple rest info", body = function( currentSpec ) {
				http url="#localhost#/rest/simpleRestInit/simpleRest/info" result="local.result";
				systemOutput( "", true );
				systemOutput( result.filecontent, true ); // returns the path
				debug( result.filecontent );
				if (result.error) throw "Error: #result.filecontent#";
			});

		});
	}

	private function dumpRestConfig(){
		var cfconfig = DeSerializeJson(fileRead( expandPath('{lucee-config}.CFConfig.json') ) );
		systemOutput( "---------------cfconfig------------", true );
		var rest = cfconfig.rest ?: { "noRestConfig": true };
		systemOutput( serializeJson( var=rest, compact=false ), true );
	}
}