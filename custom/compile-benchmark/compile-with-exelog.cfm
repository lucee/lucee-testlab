<cfscript>
// Enable server-scoped execution log so PageImpl emits getExecutableLines() + exeLogStart/End.
// This is the debug-mode bytecode path used by the debugger extension at runtime.
// The "debug" shortcut is a config-file loader alias — the cfadmin tag needs the FQN.
admin
	action="updateExecutionLog"
	type="server"
	password="admin"
	class="lucee.runtime.engine.DebugExecutionLog"
	arguments=structNew()
	enabled=true;

// Delegate to the standard compile-benchmark loop.
include template="index.cfm";
</cfscript>
