<cfscript>
	// JIT warmup — runs first (alphabetical), exercises basic request path
	r = "hello";
	if ( r != "hello" ) throw "aaa-hello: sanity check failed";
</cfscript>
