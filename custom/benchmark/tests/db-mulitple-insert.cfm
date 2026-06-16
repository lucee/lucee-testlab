<cfscript>
	params = {
		test1: { value: createUUID(), sqltype: "varchar" },
		test2: { value: createUUID(), sqltype: "varchar" },
		test3: { value: createUUID(), sqltype: "varchar" },
		test4: { value: createUUID(), sqltype: "varchar" },
		test5: { value: createUUID(), sqltype: "varchar" }
	};

	query params=params result="result" datasource="mysql" {
		echo( "INSERT INTO benchmark_noidx( test ) VALUES ( :test1 ), ( :test2 ), ( :test3 ), ( :test4 ), ( :test5 )" );
	}

</cfscript>