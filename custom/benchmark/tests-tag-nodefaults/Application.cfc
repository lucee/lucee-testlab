component {

	this.name = "bench-tag-nodefaults-#hash( getCurrentTemplatePath() )#";
	this.sessionManagement = false;

	// control: no this.tag, so the defaults map is null and the lookup returns before building a key on either jar

}
