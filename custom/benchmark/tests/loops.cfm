<cfset variables.iteration = 5000>
<cfset variables.x = 0>
<cfset variables.tick = getTickCount()>
<cfloop from="1" to="#variables.iteration#" index="variables.i">
    <cfset variables.x = variables.i + 1>
</cfloop>
<cfoutput>#getTickCount()-variables.tick#ms<hr></cfoutput>

<cfscript>
    variables.tick = getTickCount();
    variables.x=0;
    for (variables.i=1; variables.i<=variables.iteration;variables.i++) {
        variables.x = variables.i+1;
    }
    writeOutput(getTickCount()-variables.tick);
    writeoutput( '<hr>' );
</cfscript>

<cfscript>
    variables.tick = getTickCount();
    variables.x = 0;
    cfloop ( from=1, to=variables.iteration, index="variables.i") {
        variables.x = variables.i+1;
    }
    writeOutput(getTickCount()-variables.tick);
</cfscript>