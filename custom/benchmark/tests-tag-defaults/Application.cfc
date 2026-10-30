component {

	this.name = "bench-tag-defaults-#hash( getCurrentTemplatePath() )#";
	this.sessionManagement = false;

	// same shape as Preside's Bootstrap.cfc: two defaults, neither for a tag these pages use,
	// so every tag call looks up the map and misses
	this.tag.location.addToken = false;
	this.tag.function.bufferoutput = true;

}
