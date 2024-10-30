
<cfscript>
    // see https://luceeserver.atlassian.net/browse/LDEV-1541

    function calcPrimes() localmode=true {
        ticks = getTickCount();
        stopIndex   = 250;
        primes      = [];
        divisions   = 0;
        ArrayAppend(primes, 2);
        ArrayAppend(primes, 3);
        n = 5;
        for (n; n < stopIndex; n += 2) {
            isPrime = true;
            d = 3;
            for (d; d < n; d++) {
                divisions++;
                if (n % d == 0) {
                    isPrime = false;
                    break;
                }
            }
            if (isPrime) {
                ArrayAppend(primes, n);
            }
        }
        ticks = (getTickCount() - ticks);
        numPrimes = arrayLen(primes);
        echo("#numberFormat(divisions)# divisions in #ticks# ms.<br>");
        echo("#numberFormat(numPrimes)# prime numbers found below #numberFormat(stopIndex)#");
        return numPrimes;
    }

    numPrimes = calcPrimes();
    

    if ( 53 != numPrimes)
        throw "Expected 53 primes, got #numPrimes#";
</cfscript>

