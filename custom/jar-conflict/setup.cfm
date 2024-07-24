<cfscript>

    dir = getDirectoryFromPath(getCurrentTemplatePath()) & "poi-ext";
    directoryCreate( dir );

    if (false){
        // use jars from maven
        files = [
            "https://repo1.maven.org/maven2/org/apache/poi/poi-ooxml/5.3.0/poi-ooxml-5.3.0.jar",
            "https://repo1.maven.org/maven2/org/apache/poi/poi/5.3.0/poi-5.3.0.jar"
        ];

        for ( fileUrl in files ){
            http url=fileUrl path=dir file=ListLast( fileUrl,"/ ");
        }
    } else if ( false ){
        // use lucee poi jars from the poi extension
        lex=  "https://ext.lucee.org/poi-extension-1.0.0.6-BETA.lex";
        http url=lex path=getTempDirectory() file="poi.lex";
        extract( "zip", getTempDirectory() & "poi.lex", dir );
    } else {
        // use lucee poi jars from the poi extension
        zip = "https://archive.apache.org/dist/poi/release/bin/poi-bin-3.12-20150511.zip";
        http url=zip path=getTempDirectory() file="poi.zip";
        extract( "zip", getTempDirectory() & "poi.zip", dir );
    }
    files = directoryList( dir, true );
    for ( file in files ){
        if ( listLast( file, "." ) eq "jar" )
            systemOutput( file, true );
    }

    contextLibDir = ExpandPath('{lucee-config}') & "/lib";

    for ( file in files ){
        if ( listLast( file, ".") eq "jar" && listLast( file, "/") contains "poi-" ){
            systemOutput( "copying [#file#] to [#contextLibDir#]", true );
            fileCopy( file, contextLibDir );
        }
    }
    contextLibDir = ExpandPath('{lucee-config}') & "/lib";

    files = directoryList( contextLibDir, true );
    systemOutput( files );


</cfscript>
