<cfscript>
    dir      = GetDirectoryFromPath( GetCurrentTemplatePath() ) & "/";
    files= directoryList(path=dir, recurse=true);
    util = createObject("java","lucee.commons.io.res.util.ResourceUtil")
    for (f in files){
        echo(util.getCanonicalResourceEL(fileOpen(f & "").getResource()) & "<br>");
    }
</cfscript>