<cfset variables.iteration = 5000>
<cfscript>
    variables.tick = getTickCount();
    variables.x=0;
    for (variables.i=1; variables.i<=variables.iteration;variables.i++) {
        //variables.x = variables.i+1;
    }
    writeOutput(getTickCount()-variables.tick);
    writeoutput( '<hr>' );
</cfscript>
