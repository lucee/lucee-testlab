<cfscript>
    dir      = GetDirectoryFromPath( GetCurrentTemplatePath() ) & "/res/qrcodes/lib";
    jarFiles = DirectoryList( dir, true, "query" );
    /* disabled as it's ridiculously slow before 6.2.0.266
    for (file in jarFiles) {
        echo( file.mode & "<br>" ); // trigger getMode https://luceeserver.atlassian.net/browse/LDEV-5227
    }
    */
</cfscript>