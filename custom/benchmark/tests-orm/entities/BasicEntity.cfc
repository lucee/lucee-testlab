component persistent="true" table="basic_entity" accessors="true" {
	property name="id" fieldtype="id" generator="native" ormtype="integer";
	property name="name" type="string" ormtype="string";
	property name="status" type="string" ormtype="string" index="idx_status";
	property name="created" type="date" ormtype="timestamp";
	property name="score" type="numeric" ormtype="integer" index="idx_score";
}
