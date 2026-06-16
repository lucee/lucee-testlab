component persistent="true" table="ten_props_entity" accessors="true" {
	property name="id" fieldtype="id" generator="native" ormtype="integer";
	property name="firstName" type="string" ormtype="string";
	property name="lastName" type="string" ormtype="string";
	property name="email" type="string" ormtype="string";
	property name="phone" type="string" ormtype="string";
	property name="role" type="string" ormtype="string";
	property name="department" type="string" ormtype="string";
	property name="status" type="string" ormtype="string" index="idx_ten_status";
	property name="score" type="numeric" ormtype="integer" index="idx_ten_score";
	property name="active" type="boolean" ormtype="boolean";
	property name="created" type="date" ormtype="timestamp";
}
