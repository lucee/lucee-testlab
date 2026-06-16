<cfscript>
// Probe each ORM entity, report routing via getMetaData().

entities = [
	"entities.BasicEntity",
	"entities.CycleEntity",
	"entities.FivePropsEntity",
	"entities.TenPropsEntity",
	"entities.WriteEntity"
];

systemOutput( "", true );
systemOutput( "  routing            persistent  accessors  Entity", true );
systemOutput( repeatString( "-", 70 ), true );

for ( entityName in entities ) {
	meta = getComponentMetadata( entityName );
	hasBody = meta.hasPseudoConstructorBody ?: "n/a";
	routing = (hasBody === true) ? "TRUE  (today)  " : ( (hasBody === false) ? "FALSE (factory)" : "?              " );
	persistent = meta.persistent ?: false;
	accessors = meta.accessors ?: false;
	systemOutput( "  " & routing & "    " & ( persistent ? "true " : "false" ) & "       " & ( accessors ? "true " : "false" ) & "      " & entityName, true );
}

systemOutput( "", true );
</cfscript>
