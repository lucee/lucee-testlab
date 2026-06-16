<cfscript>
	// Spec #4 (toBytes / readAllBytes): big binary file read, 5 calls per cycle.
	// fileReadBinary() routes through IOUtil.toBytes(BufferedInputStream)
	// -> toBytes(InputStream, false) at IOUtil.java:1174-1178, which uses
	// ByteArrayOutputStream doubling growth (~26 MB garbage for a 10 MB stream,
	// ~3 MB garbage for our 1 MB fixture). Future readAllBytes() fix should
	// drop allocation by ~50-60% on this path.
	for ( i = 1; i <= 5; i++ ) {
		fileReadBinary( application.ioutilBigBinary );
	}
</cfscript>
