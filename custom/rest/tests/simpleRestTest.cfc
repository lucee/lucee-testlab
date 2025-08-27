component extends="org.lucee.cfml.test.LuceeTestCase" labels="rest" {

	variables.localhost="http://127.0.0.1:8888";

	function beforeAll(){


		// NOTE this is running in script runner, not on the express server!
		/*
		var restPath = expandPath( getDirectoryFromPath(getCurrentTemplatePath()) & "../express-tests/simpleRest") & "/";
	
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
		new "../express-tests/dumpRestConfig"().dumpRestConfig();
		*/
		systemOutput("---------remote express server---------", true);
		// this performs the same config on the express server
		http url="#localhost#/restTest/express-tests/simpleRest/setupSimpleRestTest.cfm" result="local.result";
		systemOutput( "", true );
		systemOutput( result.filecontent, true ); // returns the path
		debug( result.filecontent );
		if (result.error) throw "Error: #result.filecontent#";

	}

	function run( testResults , testBox ) {
		describe( title="Lucee Simple REST tests - cfadmin", body=function() {

			it(title="test REST List services", body = function( currentSpec ) {
				http url="#localhost#/rest/" result="local.result";
				systemOutput( "", true );
				systemOutput( result.filecontent, true );
				debug( result.filecontent );
				expect( result.filecontent ).toInclude( "Available sevice mappings are:" );
			});

			it(title="simple rest info", body = function( currentSpec ) {
				http url="#localhost#/rest/simpleRest/simpleRest/info" result="local.result";
				systemOutput( "", true );
				systemOutput( result.filecontent, true ); // returns the path
				debug( result.filecontent );
				if (result.error) throw "Error: #result.filecontent#";
			});

		});
	}

}