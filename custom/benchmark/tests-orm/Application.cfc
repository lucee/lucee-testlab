component {
	this.name = "bench-orm-#hash( getCurrentTemplatePath() )#";
	this.sessionManagement = false;
	this.logs = {
		orm: { appender: "resource", level: "error" }
	};

	this.datasource = "mysql";
	this.datasources = {
		mysql: {
			class: 'com.mysql.cj.jdbc.Driver'
			, bundleName: 'com.mysql.cj'
			, connectionString: 'jdbc:mysql://127.0.0.1:3306/lucee_orm_bench?useSSL=false&allowPublicKeyRetrieval=true'
			, bundleVersion: "9.5.0"
			, username: "lucee"
			, password: "lucee"
			, connectionLimit: 60
		}
	};

	this.ormEnabled = true;
	this.ormSettings = {
		dbcreate: "update",
		cfclocation: [ getDirectoryFromPath( getCurrentTemplatePath() ) & "entities" ],
		flushAtRequestEnd: false,
		autoManageSession: false,
		skipCFCWithError: false
	};

	function onApplicationStart() {
		inspectTemplates();
		// clean slate, then seed data for read-only tests
		query datasource="mysql" { echo( "TRUNCATE basic_entity" ); }
		query datasource="mysql" { echo( "TRUNCATE five_props_entity" ); }
		query datasource="mysql" { echo( "TRUNCATE ten_props_entity" ); }
		loop from=1 to=50 index="local.i" {
			var e = EntityNew( "BasicEntity" );
			e.setName( "user_#i#" );
			e.setStatus( i mod 2 ? "active" : "inactive" );
			e.setCreated( now() );
			e.setScore( i );
			EntitySave( e );

			var t = EntityNew( "TenPropsEntity" );
			t.setFirstName( "first_#i#" );
			t.setLastName( "last_#i#" );
			t.setEmail( "user#i#@example.com" );
			t.setPhone( "555-#numberFormat( i, '0000' )#" );
			t.setRole( "role_#i mod 3#" );
			t.setDepartment( "dept_#i mod 4#" );
			t.setStatus( i mod 2 ? "active" : "inactive" );
			t.setScore( i );
			t.setActive( true );
			t.setCreated( now() );
			EntitySave( t );
		}
		ormFlush();
	}
}
