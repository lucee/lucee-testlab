<cfscript>
// Setup table once
if ( !structKeyExists( server, "lucee_testlab_db_select" ) ) {
	query datasource="mysql" {
		echo( "DROP TABLE IF EXISTS benchmark_select" );
	}

	query datasource="mysql" {
		echo( "
			CREATE TABLE IF NOT EXISTS benchmark_select (
				id INT AUTO_INCREMENT PRIMARY KEY,
				varchar_col VARCHAR(100),
				int_col INT,
				decimal_col DECIMAL(10,2),
				date_col DATE,
				timestamp_col TIMESTAMP,
				text_col TEXT
			)
		" );
	}

	// Insert test data
	query datasource="mysql" {
		echo( "
			INSERT INTO benchmark_select (varchar_col, int_col, decimal_col, date_col, timestamp_col, text_col)
			VALUES
				('test1', 100, 99.99, '2025-01-01', '2025-01-01 12:00:00', 'Sample text 1'),
				('test2', 200, 199.99, '2025-01-02', '2025-01-02 13:00:00', 'Sample text 2'),
				('test3', 300, 299.99, '2025-01-03', '2025-01-03 14:00:00', 'Sample text 3')
		" );
	}

	server.lucee_testlab_db_select = true;
}
</cfscript>

<cfquery name="result" datasource="mysql">
	SELECT * FROM benchmark_select
	WHERE varchar_col = <cfqueryparam value="test1" cfsqltype="cf_sql_varchar">
	AND int_col = <cfqueryparam value="100" cfsqltype="cf_sql_integer">
	AND decimal_col = <cfqueryparam value="99.99" cfsqltype="cf_sql_decimal">
	AND date_col = <cfqueryparam value="2025-01-01" cfsqltype="cf_sql_date">
	AND timestamp_col = <cfqueryparam value="2025-01-01 12:00:00" cfsqltype="cf_sql_timestamp">
	AND text_col = <cfqueryparam value="Sample text 1" cfsqltype="cf_sql_longvarchar">
	ORDER BY int_col
</cfquery>

<cfquery name="result" datasource="mysql" returnType="struct" columnKey="int_col">
	SELECT * FROM benchmark_select
	WHERE varchar_col = <cfqueryparam value="test1" cfsqltype="cf_sql_varchar">
	AND int_col = <cfqueryparam value="100" cfsqltype="cf_sql_integer">
	AND decimal_col = <cfqueryparam value="99.99" cfsqltype="cf_sql_decimal">
	AND date_col = <cfqueryparam value="2025-01-01" cfsqltype="cf_sql_date">
	AND timestamp_col = <cfqueryparam value="2025-01-01 12:00:00" cfsqltype="cf_sql_timestamp">
	AND text_col = <cfqueryparam value="Sample text 1" cfsqltype="cf_sql_longvarchar">
	ORDER BY int_col
</cfquery>

<cfquery name="result" datasource="mysql" returnType="array">
	SELECT * FROM benchmark_select
	WHERE varchar_col = <cfqueryparam value="test1" cfsqltype="cf_sql_varchar">
	AND int_col = <cfqueryparam value="100" cfsqltype="cf_sql_integer">
	AND decimal_col = <cfqueryparam value="99.99" cfsqltype="cf_sql_decimal">
	AND date_col = <cfqueryparam value="2025-01-01" cfsqltype="cf_sql_date">
	AND timestamp_col = <cfqueryparam value="2025-01-01 12:00:00" cfsqltype="cf_sql_timestamp">
	AND text_col = <cfqueryparam value="Sample text 1" cfsqltype="cf_sql_longvarchar">
	ORDER BY int_col
</cfquery>
