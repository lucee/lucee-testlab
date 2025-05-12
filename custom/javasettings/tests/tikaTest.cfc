component extends="org.lucee.cfml.test.LuceeTestCase" labels="javasettings" {

	function run( testResults , testBox ) {
		describe( title="Test Tika", body=function() {

			it(title="load tika via javasettings ", body = function( currentSpec ) {
				var t = _getTika();
				var bi = bundleInfo(t);
				expect( bi.version ).toBe( "1.28.5" );
			});

			it(title="load tika via javasettings again", body = function( currentSpec ) {
				var t = _getTika();
				var bi = bundleInfo(t);
				expect( bi.version ).toBe( "1.28.5" );
			});
	
		});
	}

	private function _getTika(){
		// lucee bundles 1.24
		var tikaComponent = new component javaSettings='{
				"maven": [ "org.apache.tika:tika:1.28.5" ]
			}' {
			
			import org.apache.tika.Tika;

			function getTika(){
				return new Tika();
			}
		};

		return tikaComponent.getTika();

	}
}