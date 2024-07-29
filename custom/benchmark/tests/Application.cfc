component {
	this.name="bench";
	this.datasource = {
		class: 'com.mysql.cj.jdbc.Driver'
		, bundleName: 'com.mysql.cj'
		, connectionString: 'jdbc:mysql://127.0.0.1:3306/lucee_fallback?useSSL=false'
		, username: "lucee_fallback"
		, password: "lucee_fallback"
	}; // fallback

	this.datasources = {
		mysql: {
			class: 'com.mysql.cj.jdbc.Driver'
			, bundleName: 'com.mysql.cj'
			, connectionString: 'jdbc:mysql://127.0.0.1:3306/lucee?useSSL=false'
			, username: "lucee"
			, password: "lucee"
		}
	};

	function onApplicationStart(){
		query datasource="mysql" {
			echo("drop table if exists benchmark")
		}
	
		query datasource="mysql" {
			echo("create table benchmark (id INT AUTO_INCREMENT PRIMARY KEY, test VARCHAR( 36 ) )")
		}
	}

}