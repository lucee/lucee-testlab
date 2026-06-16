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

		loop list="benchmark_select,benchmark_select_named" item="tbl" {
			query datasource="mysql" {
				echo("drop table if exists #tbl#");
			}
			query datasource="mysql" {
				echo("
					create table #tbl# (
						id INT AUTO_INCREMENT PRIMARY KEY,
						varchar_col VARCHAR(100),
						int_col INT,
						decimal_col DECIMAL(10,2),
						date_col DATE,
						timestamp_col TIMESTAMP,
						text_col TEXT
					)
				");
			}
			query datasource="mysql" {
				echo("
					insert into #tbl# (varchar_col, int_col, decimal_col, date_col, timestamp_col, text_col)
					values
						('test1', 100, 99.99, '2025-01-01', '2025-01-01 12:00:00', 'Sample text 1'),
						('test2', 200, 199.99, '2025-01-02', '2025-01-02 13:00:00', 'Sample text 2'),
						('test3', 300, 299.99, '2025-01-03', '2025-01-03 14:00:00', 'Sample text 3')
				");
			}
		}
	}

}
