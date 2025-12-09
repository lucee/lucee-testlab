<cfscript>
// Test for LDEV-5960 - extension without startup hook
// This tests if extensions without startup hooks are available on first request
writeOutput( GetLazyConfig() );
</cfscript>
