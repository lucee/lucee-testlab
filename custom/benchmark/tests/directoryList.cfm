<cfscript>
    dir      = GetDirectoryFromPath( GetCurrentTemplatePath() ) & "/res/qrcodes/lib";
    jarFiles = DirectoryList( dir, true, "query" );
    for (file in jarFiles) {
        echo( file.mode & "<br>" ); // trigger getMode https://luceeserver.atlassian.net/browse/LDEV-5227
    }
</cfscript>