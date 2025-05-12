component extends="org.lucee.cfml.test.LuceeTestCase" labels="javasettings" {

	function run( testResults , testBox ) {
		describe( title="Test Tika", body=function() {

			it(title="load tika via javasettings ", body = function( currentSpec ) {
				var t = getTikaCFC().getTika();
				systemOutput(getMetaData(t), true);
				systemOutput(t.getClass(), true);
			});

			it(title="load tika via javasettings again", body = function( currentSpec ) {
				var t = getTikaCFC().getTika();
				systemOutput(getMetaData(t), true);
				systemOutput(t.getClass(), true);
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

		return new tikaComp();

	}
}