<cfscript>
	e = EntityNew( "WriteEntity" );
	e.setName( "user_#createUniqueId()#" );
	e.setStatus( "active" );
	e.setCreated( now() );
	e.setScore( randRange( 1, 100 ) );
	EntitySave( e );
	ormFlush();
</cfscript>
