<cfscript>
    request.started = now();
    request.i = 1;
    request.i++;
    for (i=0; i < 1030; i++){
        request[i]=1;
    }
</cfscript>