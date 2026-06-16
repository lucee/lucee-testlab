component {
	public function init() {
		variables.name = "";
		variables.value = 0;
		variables.active = false;
		variables.dateCreated = now();
		variables.description = "";
		return this;
	}
}
