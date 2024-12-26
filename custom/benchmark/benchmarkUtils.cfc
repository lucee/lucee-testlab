component  {

	function getTests( string filter="" ){
		if ( len( trim( filter ) ) ){
			systemOutput("Filtering tests by [#filter#]", true);
			var testDir = GetDirectoryFromPath( GetCurrentTemplatePath() ) & "/tests";
			var availableSuites = DirectoryList( testDir, true, "path" )
			var suites = [];
			for ( var suite in availableSuites ){
				if ( suite contains filter && listLast( suite, "." ) eq "cfm" )
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
				else if ( col eq "error" or col eq "snippet" )
					arrayAppend( row, markdownEscape( q [ col ] ) );  // newlines and pipes are not allowed in markdown tables
				else if ( left( col, 1 ) eq "_" ) {
					if ( q [ col ] gt 1 )
						arrayAppend( row, numberFormat( q [ col ] ) );
					else 
						arrayAppend( row, decimalFormat( q [ col ] ) );
				}
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

	// quick n dirty, but enough for now
	function checkMinLuceeVersion( major, min ){
		var version = server.lucee.version;
		var parts = listToArray( version, "." );
		if ( parts[ 1 ] gte arguments.major and parts[ 2 ] gte arguments.min )// and parts[ 3 ] eq 7 )
			return true;
		else if ( parts[ 1 ] gt arguments.major)
			return true;
		return false;
	}

	function reportTests( runs, 
			sectionTitle="Suite / Spec", 
			sectionKey="suiteName", 
			detailTitle="", 
			detailKey="", 
			statKey="time",
			boolean sort=false ) localmode=true {

		var sortedRuns = duplicate( runs );

		arraySort(
			sortedRuns,
			function (e1, e2){
				return compare(e1.version & e1.java, e2.version & e2.java);
			}
		); // sort runs by oldest version to newest version


		var hdr = [ arguments.sectionTitle ];
		var div = [ "---" ];
		if ( len( arguments.detailTitle ) ){
			arrayAppend( hdr, arguments.detailTitle );
			arrayAppend( div, "---" );
		}
		loop array=sortedRuns item="local.run" {
			arrayAppend( hdr, run.version & " " & listFirst( run.java, "." ) );
			arrayAppend( div, "---:" ); // right align as they are all numeric
		}

		// diff column, first run vs last run
		arrayAppend( hdr, "Difference (oldest vs newest)" );
		arrayAppend( div, "---:" ); // right align as they are all numeric

		_logger( "" );
		_logger( "|" & arrayToList( hdr, "|" ) & "|" );
		_logger( "|" & arrayToList( div, "|" ) & "|" );

		// now sort the tests by the difference in time between the first run and last run
		var suiteSpecs = [];
		if ( arguments.sort ){
			var suiteSpecsDiff = {};

			loop collection=runs[1].stats key="title" value="test" {
				// difference between the test time for the newest version minus oldest version
				var diff = sortedRuns[ arrayLen( runs ) ].stats[ arguments.sectionKey ][ arguments.statKey ] 
					- sortedRuns[ 1 ].stats[ arguments.sectionKey ][ arguments.statKey ];
				ArrayAppend( suiteSpecs, {
					id: test[ arguments.sectionKey ],
					diff: diff
				});
				suiteSpecsDiff[ test.suiteSpec ] = diff;
			}

			arraySort(
				suiteSpecs,
				function ( e1, e2 ){
					if ( e1.diff gt e2.diff ) return -1;
					else if ( e1.diff lt e2.diff ) return 1;
					return 0;
				}
			); // sort by performance regression
		} else {
			loop collection=runs[1].stats key="title" value="test" {
				ArrayAppend( suiteSpecs, {
					id: test[ arguments.sectionKey ],
					diff: -1
				});
			}
		}

		/*
		systemOutput("", true);
		systemOutput(suiteSpecs, true);

		systemOutput("", true);
		systemOutput(sortedRuns, true);
		systemOutput("", true);
		*/

		var row = [];
		loop array=suiteSpecs item="test" {
			ArrayAppend( row, markdownEscape( wrap( sortedRuns[ 1 ].stats[ test.id ] [arguments.sectionKey ], 70 ) ) );
			if ( len( arguments.detailTitle ) )
				ArrayAppend( row, markdownEscape( wrap( sortedRuns[ 1 ].stats[ test.id ][ arguments.detailKey ], 70 ) ) );

			loop array=sortedRuns item="local.run" {
				if ( structKeyExists( run.stats, test.id ) ) {
					var rowStats="";
					if ( isSimpleValue( arguments.statKey ) ){
						rowStats = numFormat( run.stats[ test.id ][ arguments.statKey ] );
					} else {
						var delim = "";
						arrayEach( arguments.statKey, function( key ){
							var n = run.stats[ test.id ][ key ];
							rowStats &= delim & numFormat( n );
							delim = " / ";
						});
					}
					arrayAppend( row, rowStats );
				} else {
					arrayAppend( row, "" );
				}
			}
			if ( arguments.sort ){
				arrayAppend( row, numberFormat( test.diff ) );
			}
			_logger( "|" & arrayToList( row, "|" ) & "|" );
			row = [];
		}

		_logger( "" );
	}

	function markdownEscape( string str ){
		var s = replace( arguments.str, "|", "\|", "ALL" );
		s = replace( s, "`", "\`", "ALL" );
		s = REReplace( s , "\n", "\n", "ALL" );
		return s;
	}

	function numFormat( n ){
		if ( n eq 0 )
			return 0;
		else if ( n gt 1 )
			return numberFormat( n );
		else
			return decimalFormat( n );
	}

}
