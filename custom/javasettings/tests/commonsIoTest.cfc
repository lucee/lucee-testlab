component extends="org.lucee.cfml.test.LuceeTestCase" labels="javasettings" {

	function run( testResults , testBox ) {
		describe( title="Test commons io", body=function() {

			it(title="load commons io CountingPathVisitor (bundled)", body = function( currentSpec ) {
				var t = _getCommonsBundled();
				var bi = bundleInfo(t);
				expect( bi.version ).toBe( "2.16.1" );
			});

			it(title="load commons io CountingPathVisitor (2.19.0)", body = function( currentSpec ) {
				var t = _getCommons2190();
				var bi = bundleInfo(t);
				expect( bi.version ).toBe( "2.19.0" );
			});
	
		});
	}

	private function _getCommonsBundled(){
		var tikaComponent = new component {
			
			import org.apache.commons.io.file.CountingPathVisitor;

			function withLongCounters(){
				return CountingPathVisitor::withLongCounters();
			}
		};

		return tikaComponent.withLongCounters();

	}

	private function _getCommons2190(){
		var tikaComponent = new component javaSettings='{
				"maven": [ "commons-io:commons-io:2.19.0")" ]
			}' {
			
			import org.apache.commons.io.file.CountingPathVisitor;

			function withLongCounters(){
				return CountingPathVisitor::withLongCounters();
			}
		};

		return tikaComponent.withLongCounters();

	}
}