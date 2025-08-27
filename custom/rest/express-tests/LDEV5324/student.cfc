component {

	property name="name" type="string";
	property name="age" type="numeric";

	function init(name, age){
		this.name = arguments.name;
		this.age = arguments.age;
		_debug("init()", arguments );
		return this;
	}

	remote function getStudent() returntype="any" httpmethod="GET" produces="application/json" {
		_debug("getStudent()", arguments );
		return this;
	}

	remote function updateStudent() returntype="void" httpmethod="PUT" {
		_debug("updateStudent()", arguments );
	}

	remote function deleteStudent() returntype="boolean" httpmethod="DELETE" {
		_debug("deleteStudent()", arguments );
		return true;
	}

	private function _debug(method, args){
		return;
		systemOutput(method, true);
		systemOutput(args.toJson(), true);
	}

}