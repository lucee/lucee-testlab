component  {

	function getTests( string filter="" ){
		if ( len( trim( filter ) ) ){
			var testDir = GetDirectoryFromPath( GetCurrentTemplatePath() ) & "/tests";
			var availableSuites = DirectoryList( testDir, true, "path" )
			var suites = [];
			for ( var suite in availableSuites ){
				if ( suite contains filter )
					arrayAppend( suites, listFirst( listLast( suite, "/\" ), "." ) );
			}
		} else {
			var suites = application.testSuite;
		}
		
		var longestName =  [];
		arrayEach( suites, function( item ){
			arrayAppend( longestName, len( item ) );
		});
		return {
			suites = suites.toList(),
			longestSuiteName = arrayMax( longestName )
		};
	}

	function dumpTable( query q, string title="", boolean console=true ) localmode=true {
	
		if ( q.recordCount eq 0 )
			return;

		var hdr = [];
		var div = [];
		loop list=q.columnlist item="local.col" {
			if ( col eq "_perc" )
				arrayAppend( hdr, "%" );
			else 
				arrayAppend( hdr, replace( col, "_", "") );
			if ( col eq "memory" or col eq "time" or col eq "throughput" or left( col, 1 ) eq "_" )
				arrayAppend( div, "---:" );
			else
				arrayAppend( div, "---" );
		}
		if ( len( trim( arguments.title ) ) ){
			_logger( message="", console=arguments.console );
			_logger( message="###### #arguments.title#", console=arguments.console );
		}
		_logger( message="", console=arguments.console );
		_logger( message="|" & arrayToList( hdr, "|" ) & "|", console=arguments.console );
		_logger( message="|" & arrayToList( div, "|" ) & "|", console=arguments.console );

		var row = [];
		loop query=q {
			if ( QueryColumnExists(q, "_perc") ){
				if ( q.time[ 1 ] neq 0 )
					querySetCell( q, "_perc", 100 - int(( q.time[ 1 ] / q.time[ q.currentRow ]  ) * 100) , q.currentRow ) ;
				if ( q._perc neq 0 )
					querySetCell( q, "_perc", "-#abs(q._perc)#", q.currentRow ) ;
			}
			loop list=q.columnlist item="local.col" {
				if ( col eq "memory" or col eq "time" or col eq "throughput" )
					arrayAppend( row, numberFormat( q [ col ] ) );
				else if ( col eq "_perc" )
					arrayAppend( row, numberFormat( q [ col ] ) & "%");
				else if ( col eq "error" or col eq "snippet")
					arrayAppend( row, htmleditformat( REReplace( q [ col ], "\n", " ", "ALL") ) );
				else 
					arrayAppend( row, q [ col ] );
			}
			_logger( message="|" & arrayToList( row, "|" ) & "|", console=arguments.console );
			row = [];
		}

		_logger( message="", console=arguments.console );
	}

	function _logger( string message="", boolean throw=false, console=true ){
		if ( arguments.console )
			systemOutput( arguments.message, true );
		if ( !len( server.system.environment.GITHUB_STEP_SUMMARY?:"" ))
			return;
		if ( !FileExists( server.system.environment.GITHUB_STEP_SUMMARY  ) ){
			fileWrite( server.system.environment.GITHUB_STEP_SUMMARY, "#### #server.lucee.version# ");
			fileAppend( server.system.environment.GITHUB_STEP_SUMMARY, server.system.environment.toJson());
		}

		if ( arguments.throw ) {
			fileAppend( server.system.environment.GITHUB_STEP_SUMMARY, "> [!WARNING]" & chr(10) );
			fileAppend( server.system.environment.GITHUB_STEP_SUMMARY, "> #arguments.message##chr(10)#");
			throw arguments.message;
		} else {
			fileAppend( server.system.environment.GITHUB_STEP_SUMMARY, " #arguments.message##chr(10)#");
		}

	}

	struct function reportMem( string type, struct prev={}, string name="", filter="" ) {
		var qry = getMemoryUsage( type );
		var report = [];
		var used = { name: arguments.name };
		querySort(qry,"type,name");
		loop query=qry {
			if ( len( arguments.filter ) and arguments.filter neq qry.type )
				continue;
			if (qry.max == -1)
				var perc = 0;
			else
				var perc = int( ( qry.used / qry.max ) * 100 );
			//if(qry.max<0 || qry.used<0 || perc<90) 	continue;
			//if(qry.max<0 || qry.used<0 || perc<90) 	continue;
			var rpt = replace(ucFirst(qry.type), '_', ' ')
				& " " & qry.name & ": " & numberFormat(perc) & "%, " & numberFormat( qry.used / 1024 / 1024 ) & " Mb";
			if ( structKeyExists( arguments.prev, qry.name ) ) {
				var change = numberFormat( (qry.used - arguments.prev[ qry.name ] ) / 1024 / 1024 );
				if ( change gt 0 ) {
					rpt &= ", (+ " & change & "Mb )";
				} else if ( change lt 0 ) {
					rpt &= ", ( " & change & "Mb )";
				}
			}
			arrayAppend( report, rpt );
			used[ qry.name ] = qry.used;
		}
		return {
			report: report,
			usage: used
		};
	}

	function getImageBase64( img ){
		saveContent variable="local.x" {
			imageWriteToBrowser( arguments.img );
		}
		var src = listGetAt( x, 2, '"' );
		// hack suggested here https://stackoverflow.com/questions/61553399/how-can-i-save-a-valid-image-to-github-using-their-api#comment125857660_71201317
		// return mid( src, len( "data:image/png;base64," ) + 1 ); didn't work either
		return src;
	}

	function checkMinLuceeVersion(major, min){
		var version = server.lucee.version;
		var parts = listToArray( version, "." );
		if ( parts[ 1 ] gte arguments.major and parts[ 2 ] gt arguments.min )// and parts[ 3 ] eq 7 )
			return true;
		return false;
	}

}