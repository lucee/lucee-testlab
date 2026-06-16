component {
	this.name="bench";
	this.sessionManagement = false; // before LDEV-5230, internal request always created sessions
	this.datasource = {
		class: 'com.mysql.cj.jdbc.Driver'
		, bundleName: 'com.mysql.cj'
		, connectionString: 'jdbc:mysql://127.0.0.1:3306/lucee_fallback?useSSL=false&allowPublicKeyRetrieval=true'
		, bundleVersion: "9.5.0"
		, username: "lucee_fallback"
		, password: "lucee_fallback"
		, connectionLimit:60
	}; // fallback

	this.datasources = {
		mysql: {
			class: 'com.mysql.cj.jdbc.Driver'
			, bundleName: 'com.mysql.cj'
			, connectionString: 'jdbc:mysql://127.0.0.1:3306/lucee?useSSL=false&allowPublicKeyRetrieval=true'
			, bundleVersion: "9.5.0"
			, username: "lucee"
			, password: "lucee"
			, connectionLimit:320
			, maxIdle: 320
			, validate: false
		}
	};

	function onApplicationStart(){
		inspectTemplates();
		query datasource="mysql" {
			echo("drop table if exists benchmark")
		}
	
		query datasource="mysql" {
			echo("create table benchmark (id INT AUTO_INCREMENT PRIMARY KEY, test VARCHAR( 36 ) )")
		}

		query datasource="mysql" {
			echo("drop table if exists benchmark_noidx")
		}
	
		query datasource="mysql" {
			echo("create table benchmark_noidx (test VARCHAR( 36 ) )")
		}
	}

}
