component {

	this.name = "bench-ioutil-#hash( getCurrentTemplatePath() )#";
	this.sessionManagement = false;

	function onApplicationStart() {

		// fresh seed dir per app start; clean up any prior run's leftovers first
		var seedDir = getTempDirectory() & "ioutil-bench/";
		if ( directoryExists( seedDir ) ) {
			directoryDelete( seedDir, true );
		}
		directoryCreate( seedDir );

		var files = [];

		fileWrite( seedDir & "sample.txt",  repeatString( "Hello world. ", 50 ) );
		arrayAppend( files, seedDir & "sample.txt" );

		fileWrite( seedDir & "sample.json", '{"a":1,"b":[2,3,4],"c":"foo"}' );
		arrayAppend( files, seedDir & "sample.json" );

		fileWrite( seedDir & "sample.xml",  '<?xml version="1.0"?><root><a>1</a></root>' );
		arrayAppend( files, seedDir & "sample.xml" );

		fileWrite( seedDir & "sample.html", '<html><body><p>hi</p></body></html>' );
		arrayAppend( files, seedDir & "sample.html" );

		fileWrite( seedDir & "sample.css",  'body { color: red; }' );
		arrayAppend( files, seedDir & "sample.css" );

		fileWrite( seedDir & "sample.js",   'function foo(){ return 1; }' );
		arrayAppend( files, seedDir & "sample.js" );

		// JPEG magic bytes (FF D8 FF E0 'JFIF')
		var jpegHeader = javaCast( "byte[]", [
			javaCast( "byte", -1 ),
			javaCast( "byte", -40 ),
			javaCast( "byte", -1 ),
			javaCast( "byte", -32 ),
			74, 70, 73, 70
		] );
		fileWrite( seedDir & "sample.jpg", jpegHeader );
		arrayAppend( files, seedDir & "sample.jpg" );

		// no extension — forces content sniffing
		fileWrite( seedDir & "sample.noext", "plain text without extension" );
		arrayAppend( files, seedDir & "sample.noext" );

		application.ioutilDir   = seedDir;
		application.ioutilFiles = files;
		application.ioutilCount = arrayLen( files );

		// dedicated hot-file for the single-file bench
		application.ioutilHotFile = seedDir & "sample.jpg";

		// 1 MB binary file for spec #4 (toBytes/readAllBytes) bench.
		// Size chosen to exercise ByteArrayOutputStream doubling growth across
		// ~16 doublings (32 B -> 64 B -> ... -> 1 MB) without dominating I/O.
		var bigPath = seedDir & "big.bin";
		var oneMB = repeatString( "X", 1048576 );
		fileWrite( bigPath, oneMB );
		application.ioutilBigBinary = bigPath;

		// Size-graded binaries for LDEV-6367 follow-up (option 3 pool-aware toBytes).
		// Span both sides of the BYTE_ARRAY_POOL 64 KB boundary so the small-stream
		// fast-path zone is measurable separately from the pool-overflow zone.
		// Empty fixture models the dominant Preside soak shape (94% of toBytes
		// allocations are HttpServletRequestDummy.clone reading often-empty GET bodies).
		var sizes = {
			  "empty.bin"    : 0
			, "tiny.bin"     : 100
			, "small-1k.bin" : 1024
			, "small-10k.bin": 10240
			, "small-50k.bin": 51200
			, "mid-200k.bin" : 204800
		};
		var sizedFiles = {};
		for ( var fname in sizes ) {
			var path = seedDir & fname;
			fileWrite( path, sizes[ fname ] == 0 ? "" : repeatString( "X", sizes[ fname ] ) );
			sizedFiles[ fname ] = path;
		}
		application.ioutilSizedBinaries = sizedFiles;

		systemOutput(
			"IOUtil bench seeded: #arrayLen( files )# small files + 1 MB big.bin + #structCount( sizedFiles )# size-graded binaries in [#seedDir#]",
			true
		);
	}

}
