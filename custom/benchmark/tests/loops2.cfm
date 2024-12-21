<cfset variables.rounds = 5000>
<cfscript>
    //systemOutput(getApplicationSettings().preciseMath, true);
    variables.tick = getTickCount();
    variables.xxxxx=0;
    for (variables.iiii=1; variables.iiii<=variables.rounds;variables.iiii++) {
        variables.xxxxx = variables.iiii+1;
    }
    writeOutput(getTickCount()-variables.tick);
    writeoutput( '<hr>' );
</cfscript>
