component extends="org.lucee.cfml.test.LuceeTestCase" labels="rest" {

	function beforeAll(){
		systemOutput("---------remote express server---------", true);
		// this performs the same config on the express server
		http url="#localhost#/restTest/express-tests/LDEV5323/ldev5323-setup.cfm" result="local.result";
		systemOutput( "", true );
		systemOutput( result.filecontent, true ); // returns the path
		debug( result.filecontent );
		if (result.error) throw "Error: #result.filecontent#";
	}

	function run( testResults, testBox ){
		describe( "LDEV-5323", function(){

			it( "check rest component has the correct application scope", function(){
				var result = test(path="/rest/ldev5323root/ldev5323root/getApplicationName");
				expect( trim( result.filecontent ) ).toBe( '"applicationName:ldev5323"' );
			});

			it( "check rest component has the correct application scope, sub dir", function(){
				var result = test(path="/rest/ldev5323sub/ldev5323sub/getApplicationName");
				expect( trim( result.filecontent ) ).toBe( '"applicationName:ldev5323"' );
			});

		} );
	}

	private function test(path, method, args={}){
		var host = "http://127.0.0.1:8888";
		var webUrl = host & arguments.path;
		systemOutput("could do http! testing via [#webUrl#]", true);
	
		var httpResult = "";
		http method="#arguments.method#" url="#webUrl#" result="httpResult"{
			structEach(arguments.args, function(k,v){
				httpparam name="#k#" value="#v#" type="url";
			});
		}

		// force cfhttp result to be like internalRequest result;
		httpResult.cookies = queryToStruct(httpResult.cookies, "name");
		httpResult.headers = httpResult.responseHeader;
		debug(httpResult,"cfhttp");
		systemOutput("REST endpoint [#method#] [#path#] returned [#httpResult.statuscode#] [#httpResult.filecontent#]", true)
		systemOutput("", true);
		return httpResult;
	}

	private string function createURI(string calledName, boolean contract=false){
		var base = getDirectoryFromPath( getCurrentTemplatePath() );
		var baseURI = contract ? contractPath( base ) : "/test/#listLast(base,"\/")#";
		return baseURI & "/" & calledName;
	}
}