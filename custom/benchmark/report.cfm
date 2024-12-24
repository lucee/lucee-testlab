<cfscript>
	dir = getDirectoryFromPath( getCurrentTemplatePath() ) & "artifacts";
	files = directoryList( dir );
	
	q = queryNew( "version,java,type,time,runs,inspect,memory,throughput,_min,_max,_avg,_med,error,raw,_perc" );
	for ( f in files ){
		systemOutput ( f, true );
		json = deserializeJson( fileRead( f ) );

		json.run.java = listFirst( json.run.java, "." );

		memory = 0;
		for ( m in json.memory.usage ){
			if ( isNumeric( json.memory.usage[ m ] ) )
				memory += json.memory.usage[ m ];
		}
		json.run.memory = int( memory / 1024 / 1024 );

		for ( r in json.data ){
			StructAppend( r, json.run );
			r.throughput = int( r.runs / ( r.time / 1000 ) );
			row = queryAddRow( q );
			QuerySetRow( q, row, r );
		}
	}

	runs = q.runs;

	_logger( "## Summary Report" );

	loop list="never,once" item="inspect" {
		loop list="#application.testSuite.toList()#" item="type" {
			dumpTable( q, type, inspect, replace(type,"-", " ", "all") & " - " & UCase( inspect ) );
		}
	}

	function _logger( string message="", boolean throw=false ){
		if ( !len( server.system.environment.GITHUB_STEP_SUMMARY?:"" ) ) {
			systemOutput( arguments.message, true );
			if ( arguments.throw )
				throw arguments.message;
			return;
		}
		if ( !FileExists( server.system.environment.GITHUB_STEP_SUMMARY ) ){
			fileWrite( server.system.environment.GITHUB_STEP_SUMMARY, "#### #server.lucee.version# ");
			//fileAppend( server.system.environment.GITHUB_STEP_SUMMARY, server.system.environment.toJson());
		}

		if ( arguments.throw ) {
			fileAppend( server.system.environment.GITHUB_STEP_SUMMARY, "> [!WARNING]" & chr(10) );
			fileAppend( server.system.environment.GITHUB_STEP_SUMMARY, "> #arguments.message##chr(10)#");
			throw arguments.message;
		} else {
			fileAppend( server.system.environment.GITHUB_STEP_SUMMARY, "#arguments.message##chr(10)#");
		}

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

   // systemOutput( serializeJSON( q, true) );

   function dumpTable( q_src, type, inspect, title ) localmode=true {

		```
		<cfquery name="local.q" dbtype="query">
			select	version, java, time, 
					throughput, _perc, _min, _avg, _med, _max, memory, error
			from	arguments.q_src
			where	type = <cfqueryparam value="#arguments.type#">
					and inspect = <cfqueryparam value="#arguments.inspect#">
			order	by throughput desc 
		</cfquery>
		```

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
		_logger( "" );
		_logger( "#### #arguments.title#" );
		_logger( "" );
		_logger( "|" & arrayToList( hdr, "|" ) & "|" );
		_logger( "|" & arrayToList( div, "|" ) & "|" );

		var row = [];
		loop query=q {
			if ( q.time[ 1 ] neq 0 )
				querySetCell( q, "_perc", 100 - int(( q.time[ 1 ] / q.time[ q.currentRow ]  ) * 100) , q.currentRow ) ;
			if ( q._perc neq 0 )
				querySetCell( q, "_perc", "-#q._perc#", q.currentRow ) ;
			loop list=q.columnlist item="local.col" {
				if ( col eq "memory" or col eq "time" or col eq "throughput" )
					arrayAppend( row, numberFormat( q [ col ] ) );
				else if ( col eq "_perc" )
					arrayAppend( row, numberFormat( q [ col ] ) & "%");
				else if ( col eq "error" )
					arrayAppend( row, htmleditformat( REReplace( q [ col ], "\n", " ", "ALL") ) );
				else 
					arrayAppend( row, q [ col ] );
			}
			_logger( "|" & arrayToList( row, "|" ) & "|" );
			row = [];
		}

		_logger( "" );
	}

</cfscript>
<!--- sigh, github doesn't suport data image urls --->
<!---

<cfquery name="mem_range" dbtype="query">
	select min(memory) as min, max(memory) as max
	from   q
</cfquery>

<cfquery name="throughput_range" dbtype="query">
	select min(throughput) as min, max(throughput) as max
	from   q
</cfquery>



<cfloop list="never,once" item="_inspect">
	<cfchart chartheight="500" chartwidth="1024" 
			title="#UCase( _inspect )# Benchmarks - #runs# runs" format="png" name="graph"
			scaleFrom="#throughput_range.min#" scaleTo="#throughput_range.max#"> 
		<cfchartseries type="line" seriesLabel="Hello World"> 
			<cfloop query="q">
				<cfif q.type eq "hello-world" and q.inspect eq _inspect>
					<cfchartdata item="#q.version# #q.java#" value="#q.throughput#"> 
				</cfif>
			</cfloop> 
		</cfchartseries>
		<cfchartseries type="line" seriesLabel="Json"> 
			<cfloop query="q">
				<cfif q.type eq "json" and q.inspect eq _inspect>>
					<cfchartdata item="#q.version# #q.java#" value="#q.throughput#"> 
				</cfif>
			</cfloop> 
		</cfchartseries> 
	</cfchart>
	<cfscript>
		_logger( "#### Inspect #UCase( _inspect )# Benchmarks - #runs# runs" );
		_logger( "" );
		_logger( "![Inspect #UCase( _inspect )# Benchmarks](#getImageBase64( graph )#)" );
		_logger( "" );
	</cfscript>
</cfloop>

<cfchart chartheight="500" chartwidth="1024" 
		title="Memory Benchmarks - #runs# runs" format="png" name="graph"
		scaleFrom="#mem_range.min#" scaleTo="#mem_range.max#"> 
	<cfchartseries type="line" seriesLabel="Memory"> 
		<cfloop query="q">
			<cfif q.type eq "hello-world" and q.inspect eq "never">
				<cfchartdata item="#q.version# #q.java#" value="#q.memory#"> 
			</cfif>
		</cfloop> 
	</cfchartseries>
</cfchart>
<cfscript>
	_logger( "#### Memory Benchmarks - #runs# runs" );
	_logger( "" );
	_logger( "![Memory Benchmarks](#getImageBase64( graph )#)" );
	_logger( "" );
</cfscript>
--->