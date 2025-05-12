component extends="org.lucee.cfml.test.LuceeTestCase" labels="javasettings" {

	function run( testResults , testBox ) {
		describe( title="Test POI via static method", body=function() {


			it(title="load poi 5.4.0 via javasettings (first time)", body = function( currentSpec ) {
				expect( _getPoi540() ).toBe( "5.4.0" );
			});

			it(title="load poi 5.4.0 via javasettings (again)", body = function( currentSpec ) {
				expect( _getPoi540() ).toBe( "5.4.0" );
			});


			it(title="load poi 5.4.1 via javasettings (first time)", body = function( currentSpec ) {
				expect( _getPoi541() ).toBe( "5.4.1" );
			});

			
			it(title="load poi 5.4.1 via javasettings (again)", body = function( currentSpec ) {
				expect( _getPoi541() ).toBe( "5.4.1" );
			});
	
		});
	}

	private function _getPoi540(){
		var poiComponent = new component javaSettings='{
				"maven": [ "org.apache.poi:poi:5.4.0" ]
			}' {
			
			import org.apache.poi.Version;

			function getVersion(){
				return Version::getVersion();
			}
		};

		return poiComponent.getVersion();

	}

	private function _getPoi541(){
		var poiComponent = new component javaSettings='{
				"maven": [ "org.apache.poi:poi:5.4.1" ]
			}' {
			
			import org.apache.poi.Version;

			function getVersion(){
				return Version::getVersion();
			}
		};

		return poiComponent.getVersion();

	}
}
