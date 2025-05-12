component extends="org.lucee.cfml.test.LuceeTestCase" labels="javasettings" {

	function run( testResults , testBox ) {
		describe( title="Test Tika", body=function() {

			it(title="load tika via javasettings ", body = function( currentSpec ) {
				var cfc = getTikaCFC()
				var t = cfc.getTika();
				systemOutput(getMetaData(t), true);
				dump(var=t, output="console");
			});

			it(title="load tika via javasettings again", body = function( currentSpec ) {
				var cfc = getTikaCFC()
				var t = cfc.getTika();
				var t = getTikaCFC().getTika();
				systemOutput(getMetaData(t), true);
				dump(var=t, output="console");
			});
	
		});
	}


	private function getTikaCFC(){
		// lucee bundles 1.24
		var tikaComp = new component javaSettings='{
				"maven": [ "org.apache.tika:tika:1.25" ]
			}' {
			
			import "org.apache.tika.Tika"

			function getTika(){
				return new Tika();
			}
		};

		return tikaComp;

	}
}