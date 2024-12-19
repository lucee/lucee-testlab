<cfscript>
    dir      = GetDirectoryFromPath( GetCurrentTemplatePath() ) & "/";
    files= directoryList(path=dir, recurse=true);
    for (f in files){
        echo(fileOpen(f & "").getResource().getCanonicalResource() & "<br>");
    }
</cfscript>