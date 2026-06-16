component {
	property name="name" type="string";
	property name="value" type="numeric";
	property name="active" type="boolean";
	property name="created" type="date";
	property name="description" type="string";

	variables.name = "";
	variables.value = 0;
	variables.active = false;
	variables.created = now();
	variables.description = "";
}
