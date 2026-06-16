component {

	this.name = "bench-lambdas-#hash( getCurrentTemplatePath() )#";
	this.sessionManagement = false;

	function onApplicationStart() {
		application.arr1k = [];
		for ( var i = 1; i <= 1000; i++ ) {
			arrayAppend( application.arr1k, i );
		}

		application.arr100 = [];
		for ( var i = 1; i <= 100; i++ ) {
			arrayAppend( application.arr100, i );
		}

		// named UDF baseline — declared once on a singleton CFC,
		// goes through UDFImpl not EnvUDF, so it's the closure-free floor
		application.utils = new utils();

		systemOutput( "Lambda bench seeded: arr1k=#arrayLen( application.arr1k )#, arr100=#arrayLen( application.arr100 )#", true );
	}

}
