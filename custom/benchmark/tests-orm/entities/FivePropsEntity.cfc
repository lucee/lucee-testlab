component persistent="true" table="five_props_entity" accessors="true" {
	property name="id" fieldtype="id" generator="native" ormtype="integer";
	property name="firstName" type="string" ormtype="string";
	property name="lastName" type="string" ormtype="string";
	property name="email" type="string" ormtype="string";
	property name="role" type="string" ormtype="string";
	property name="active" type="boolean" ormtype="boolean";
}
