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
