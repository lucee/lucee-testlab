<cfset variables.iteration = 5000>
<cfset variables.x = 0>
<cfset variables.tick = getTickCount()>
<cfloop from="1" to="#variables.iteration#" index="variables.i">
    <cfset variables.x = variables.i + 1>
</cfloop>
<cfoutput>#getTickCount()-variables.tick#ms<hr></cfoutput>
