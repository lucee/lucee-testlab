<cfscript>

    dir = getDirectoryFromPath(getCurrentTemplatePath()) & "poi-ext";

    files = directoryList( dir, true );

    poiJarPaths = [];

    systemOutput( "Poi Ext files", true );
    systemOutput( files, true );

    for ( file in files ){
        if ( listLast( file, ".") eq "jar" && listLast( file, "/") contains "poi-" )
        arrayAppend(poiJarPaths, file );
    }

    systemOutput( "createObject include jar paths", true );
    systemOutput( poiJarPaths, true );

    systemOutput( "context/lib jar files", true );
    
    contextLibDir = ExpandPath('{lucee-config}') & "/lib";
    files = directoryList( contextLibDir, true );
    systemOutput( files );

    
    // test case for https://luceeserver.atlassian.net/browse/LDEV-4998
    // Bad type on operand stack Exception calling poi
    // due to loading jars already loaded via context/lib

    function loadWorkBook(){
        var workBook = CreateObject(
            "java",
            "org.apache.poi.hssf.usermodel.HSSFWorkbook",
            poiJarPaths
        ).Init();
    }

    loadWorkBook();

    arr = [];
    arraySet( arr,1, 100, true);

    arrayEach( arr, loadWorkBook, true);
    
</cfscript>