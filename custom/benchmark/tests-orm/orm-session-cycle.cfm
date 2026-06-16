<cfscript>
	s = ormGetSession();
	e = EntityNew( "CycleEntity" );
	e.setName( "cycle" );
	e.setStatus( "active" );
	e.setCreated( now() );
	e.setScore( 1 );
	EntitySave( e );
	ormFlush();
	ormClearSession();
</cfscript>
