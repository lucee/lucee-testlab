<cfscript>
	dir = getDirectoryFromPath( getCurrentTemplatePath() ) & "artifacts";
	files = directoryList( dir );

	q = queryNew( "version,java,type,time,runs,inspect,memory,throughput,throughput_test,_min,_max,_avg,error" );
	for ( f in files ){
		systemOutput ( f, true );
		json = deserializeJson( fileRead( f ) );

		json.run.java = listFirst( json.run.java, "." );

		memory = 0;
		for ( m in json.memory.usage ){
			if ( isNumeric( json.memory.usage[ m ] ) )
				memory += json.memory.usage[ m ];
		}
		json.run.memory = int( memory / 1024 );

		for ( r in json.data ){
			StructAppend( r, json.run );
			r.throughput = int( json.run.runs / ( r.time / 1000 ) );
			row = queryAddRow( q );
			QuerySetRow( q, row, r );
		}
	}

	// now take the hello world baseline and subtract that from the other tests, so to highlight the code, excluding the request overhead

	function getBaseline(q_bench){
		```
		<cfquery name="local.q" dbtype="query" returnType="struct" columnkey="version">
			select	version, time
			from	arguments.q_bench
			where	type = 'hello-world'
					and inspect = 'never'
		</cfquery>
		```
		return q;
	}
	baseline = getBaseline( q );
	dump(baseline);
	
	

	loop query=q {
		if ( !structKeyExists(baseline, q.version) )
			test_throughput=q.time;
		else
			test_throughput=q.time-baseline[q.version].time; 
		if (q.type eq "hello-world" and q.inspect eq "never")
			test_throughput=q.time; // no baseline for the baseline is there!
		if (test_throughput > 0)
			test_throughput = int( q.runs / ( test_throughput / 1000 ) );
		/*else
			test_throughput = -1;
		*/
		querySetCell(q, "throughput_test", test_throughput , q.currentrow );
	}


	```
	<cfquery name="q2" dbtype="query">
		select	version, type, inspect, time, throughput, throughput_test, runs
		from	q
		where	type in( 'hello-world', 'json')
				-- and inspect = 'once'
		order by version, type
	</cfquery>
	```

	dump(q2);

	runs = q.runs;

	_logger( "## Summary Report" );

	loop list="once,never" item="inspect" {
		loop list="#application.testSuite.toList()#" item="type" {
			dumpTable( q, type, inspect, replace(type,"-", " ", "all") & " - " & UCase( inspect ) );
		}
	}

	function _logger( string message="", boolean throw=false ){
		// dump(message); return;
		//systemOutput( arguments.message, true );
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
			select	version, java, time, memory,
					throughput, throughput_test, _min, _avg, _max, error
			from	arguments.q_src
			where	type = <cfqueryparam value="#arguments.type#">
					and inspect = <cfqueryparam value="#arguments.inspect#">
			order	by throughput_test, throughput desc 
		</cfquery>
		```

		var hdr = [];
		var div = [];
		loop list=q.columnlist item="local.col" {
			arrayAppend( hdr, replace( col, "_", " ") );
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
			loop list=q.columnlist item="local.col" {
				if ( col eq "memory" or col eq "time" or col contains "throughput" )
					arrayAppend( row, numberFormat( q [ col ] ) );
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