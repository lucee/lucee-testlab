## Lucee REST tests

Add test rest applications under this folder

As we can't test rest applications via internalRequest in the main test suite, we add integration tests here

The test github action runs up a version of Lucee Express, these rest applications can then be tested / called over http via testbox tests in the tests folder