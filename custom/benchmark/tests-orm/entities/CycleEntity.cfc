component persistent="true" table="cycle_entity" accessors="true" {
	property name="id" fieldtype="id" generator="native" ormtype="integer";
	property name="name" type="string" ormtype="string";
	property name="status" type="string" ormtype="string";
	property name="created" type="date" ormtype="timestamp";
	property name="score" type="numeric" ormtype="integer";
}
