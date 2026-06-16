component {

	function doubler( required numeric x ) {
		return x * 2;
	}

	// loose-typed pair for doubler — fair floor vs (x)=>x*2 (no per-call cast)
	function looseDoubler( x ) {
		return x * 2;
	}

	function heavyDoubler( required numeric x ) {
		var sum = 0;
		for ( var i = 1; i <= 100; i++ ) {
			sum += x * i;
		}
		return sum;
	}

}
