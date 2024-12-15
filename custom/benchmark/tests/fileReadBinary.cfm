<cfscript>
    b = fileReadBinary("./res/cfcamp-banner.png");
    fileWrite(getTempFile(getTempDirectory(),"bin"), b);
</cfscript>