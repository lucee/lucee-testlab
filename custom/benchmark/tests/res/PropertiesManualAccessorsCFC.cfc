component {
	property name="name" type="string";
	property name="value" type="numeric";
	property name="active" type="boolean";
	property name="dateCreated" type="date";
	property name="description" type="string";

	public void function setName(string n) {
		variables.name = n;
	}
	public string function getName() {
		return variables.name;
	}

	public void function setValue(numeric v) {
		variables.value = v;
	}
	public numeric function getValue() {
		return variables.value;
	}

	public void function setActive(boolean a) {
		variables.active = a;
	}
	public boolean function getActive() {
		return variables.active;
	}

	public void function setDateCreated(date d) {
		variables.dateCreated = d;
	}
	public date function getDateCreated() {
		return variables.dateCreated;
	}

	public void function setDescription(string d) {
		variables.description = d;
	}
	public string function getDescription() {
		return variables.description;
	}
}