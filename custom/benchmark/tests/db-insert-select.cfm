<cfscript>
	params = {
		test: {value: createUUID(), sqltype="varchar" }
	};

	query params=params result="result" datasource="mysql" {
		echo( "INSERT INTO benchmark( test ) VALUES ( :test )" );
	}
	params.id = { value: result.generatedKey, sqltype="numeric" };

	query name="q" params=params datasource="mysql" {
		echo( "select id, test from benchmark where test = :test and id = :id " );
	}

	if ( q.id != params.id.value || q.test != params.test.value || q.recordcount !=1 )
		throw "invalid result [#params.toJson()#], [#q.toJson()#]";

</cfscript>