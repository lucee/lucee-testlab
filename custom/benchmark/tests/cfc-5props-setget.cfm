<cfscript>
	times = 1;
	loop times=10{
		c = new res.PropertiesAccessorsCFC();
		// Set values using setters
		c.setName("TestName" & times);
		c.setValue(times * 100);
		c.setActive(times % 2 == 0);
		c.setDateCreated(now());
		c.setDescription("Desc" & times);
		// Get values using getters
		name = c.getName();
		value = c.getValue();
		active = c.getActive();
		dateCreated = c.getDateCreated();
		description = c.getDescription();
		// Optionally do something with the values
		times++
	}
</cfscript>
