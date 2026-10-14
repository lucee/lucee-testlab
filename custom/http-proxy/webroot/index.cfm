<cfscript>
	// every check records ok / error / ms, summary.sh judges them per scenario
	env = server.system.environment;
	results = [];

	function check( required string name, required any fn ) {
		var r = { "name": arguments.name };
		var start = getTickCount();
		try {
			r[ "detail" ] = arguments.fn();
			r[ "ok" ] = true;
		} catch ( any e ) {
			r[ "ok" ] = false;
			r[ "error" ] = e.message;
			r[ "errorDetail" ] = e.detail;
			r[ "type" ] = e.type;
		}
		r[ "ms" ] = getTickCount() - start;
		arrayAppend( results, r );
		systemOutput( "[check] #r.name# ok=#r.ok# ms=#r.ms# " & ( r.ok ? r.detail : r.error ), true );
	}

	// both squids add X-Testlab-Proxy (squid/*.conf), httpbin /anything echoes the request headers back
	function viaProxy( required struct res ) {
		if ( res.status_code != 200 ) throw( message="HTTP #res.statusCode#", detail=left( res.fileContent, 300 ) );
		var headers = deserializeJSON( res.fileContent ).headers;
		return ( structKeyExists( headers, "X-Testlab-Proxy" ) ? "via #headers[ "X-Testlab-Proxy" ]#" : "direct" )
			& ( structKeyExists( headers, "Proxy-Authorization" ) ? ", Proxy-Authorization reached target" : "" );
	}

	systemOutput( "=== http-proxy [#env.SOURCE# / #env.SCENARIO#] Lucee #server.lucee.version# ===", true );

	// the sysprop is read before the env var, so an empty -Dlucee.base.config hides LUCEE_BASE_CONFIG
	check( "base config", function() {
		var prop = createObject( "java", "java.lang.System" ).getProperty( "lucee.base.config" );
		return "sysprop #isNull( prop ) ? "null" : ( len( prop ) ? "set" : "empty" )#, env #len( env.LUCEE_BASE_CONFIG ?: "" ) ? "set" : "unset"#";
	} );

	check( "server proxy", function() {
		var pd = getPageContext().getConfig().getProxyData();
		if ( isNull( pd ) ) return "none";
		return "#pd.getServer()#:#pd.getPort()#" & ( len( pd.getUsername() ?: "" ) ? " (user #pd.getUsername()#)" : "" );
	} );

	major = listFirst( server.lucee.version, "." );

	// getMavenRepository() is 8.0+, earlier versions only have LUCEE_MAVEN_DEFAULT_REPOSITORIES, ahead of Central
	check( "maven repos", function() {
		if ( major < 8 ) return "LUCEE_MAVEN_DEFAULT_REPOSITORIES [#env.LUCEE_MAVEN_DEFAULT_REPOSITORIES ?: "unset"#], then the defaults";
		var urls = [];
		loop array=getPageContext().getConfig().getMavenRepository() item="local.r" {
			arrayAppend( urls, r.getUrl() );
		}
		return arrayToList( urls, ", " );
	} );

	// what cfhttp falls back to: this.proxy (if it has a server), else the server proxy
	check( "app proxy", function() {
		var pd = getPageContext().getProxyData();
		if ( isNull( pd ) ) return "none";
		return "#pd.getServer()#:#pd.getPort()#";
	} );

	// installed at startup from .CFConfig.json, so the download already happened
	// ajax: small (250 KB), not bundled in any jar, on the extension provider (6.2, 7.x) and Maven Central (8.0)
	check( "extension from config", function() {
		var q = extensionList();
		var row = queryReduce( q, function( acc, r ) {
			return r.id == "6E2CB28F-98FB-4B51-B6BE6C64ADF35473" ? r.version : acc;
		}, "" );
		if ( !len( row ) ) throw( message="ajax extension not installed" );
		return row;
	} );

	// uniqueWorkingDir + empty user.home, so the maven store is empty
	check( "mavenLoad pinned", function() {
		var paths = mavenLoad( { groupId: "org.apache.commons", artifactId: "commons-text", version: "1.12.0" } );
		return "#arrayLen( paths )# jars";
	} );

	// a version is required before 8.0
	if ( major >= 8 ) {
		check( "mavenLoad latest", function() {
			var paths = mavenLoad( { groupId: "org.apache.commons", artifactId: "commons-csv" } );
			return "#arrayLen( paths )# jars";
		} );
	}

	check( "cfhttp http, no proxy attrs", function() {
		cfhttp( url=env.TARGET_HTTP & "/anything/no-attrs", result="local.res", timeout=10 );
		return viaProxy( local.res );
	} );

	if ( len( env.PROXY_HOST ) ) {
		check( "cfhttp http, proxyServer attr", function() {
			cfhttp( url=env.TARGET_HTTP & "/anything/attrs", result="local.res", timeout=10,
				proxyServer=env.PROXY_HOST, proxyPort=env.PROXY_PORT,
				proxyUser=env.PROXY_USER, proxyPassword=env.PROXY_PASS );
			return viaProxy( local.res );
		} );
	}

	fileWrite( env.RESULTS_FILE, serializeJSON( var=results, compact=false ) );
	systemOutput( "=== done ===", true );
</cfscript>
