<cfscript>
	for ( i = 1; i <= 100; i++ ) {
		silent {
			lock name="bench-tag-defaults" type="readonly" timeout=1 {
				savecontent variable="x" {
					echo( i );
				}
			}
		}
	}
	echo( x );
</cfscript>
