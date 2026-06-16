component {
	property name="name" type="string" default="";
	property name="value" type="numeric" default="0";
	property name="active" type="boolean" default="false";
	property name="dateCreated" type="date" default="now()";
	property name="description" type="string" default="";
	property name="arr" type="array" default="#[]#" lucee="7" rock=true;
	property name="st" type="struct" default="#{}#" lucee="6" rocks="too";
}