<cfset variables.iteration = 5000>
<cfscript>
    variables.tick = getTickCount();
    variables.x = 0;
    cfloop ( from=1, to=variables.iteration, index="variables.i") {
        variables.x = variables.i+1;
    }
    writeOutput(getTickCount()-variables.tick);
</cfscript>