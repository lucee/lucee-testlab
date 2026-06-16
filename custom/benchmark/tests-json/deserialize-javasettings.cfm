<cfscript>
	// Lucee idiom — javaSettings JSON shape used on Application.cfc / component declarations
	// to load Maven Java deps inline (see lucee-docs/api/rendering/Markdown.cfc).
	json = '{
		"maven": [
			"org.commonmark:commonmark:0.24.0"
			, "org.commonmark:commonmark-ext-gfm-strikethrough:0.24.0"
			, "org.commonmark:commonmark-ext-gfm-tables:0.24.0"
			, "org.commonmark:commonmark-ext-ins:0.24.0"
			, "org.commonmark:commonmark-ext-autolink:0.24.0"
			, "org.commonmark:commonmark-ext-image-attributes:0.24.0"
		]
	}';
	loop times=#application.innerLoop# {
		r = deserializeJson( json );
	}
	if ( arrayLen( r.maven ) != 6 ) throw "javasettings failed";
</cfscript>
