<cfscript>
    dir      = GetDirectoryFromPath( GetCurrentTemplatePath() ) & "/res/qrcodes/lib";
    jarFiles = DirectoryList( dir, true, "path" );
</cfscript>