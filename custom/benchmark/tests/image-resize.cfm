<cfscript>
	// Use lanczos interpolation to test TwelveMonkeys vs ImageResizer path
	info = imageResize( "res/sacre-coeur-paris.jpg", 600, 400, "lanczos" );
</cfscript>