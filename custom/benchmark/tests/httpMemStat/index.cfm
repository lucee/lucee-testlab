<cfscript>
	// used when running tests via http
	param name="url.gc" default="false";

	function getGcCount(){
		var javaManagementFactory = createObject( "java", "java.lang.management.ManagementFactory" );
		var gcBeans =javaManagementFactory.getGarbageCollectorMXBeans();
		var n = 0 ;
		for (var gc in gcBeans){
			var n = n + gc.getCollectionCount();
		}
		return n;
	}

	gcCount = getGcCount();

	if (url.gc)
		createObject( "java", "java.lang.System" ).gc(); // do the gc after measuring
	
	echo(gcCount);
;</cfscript>