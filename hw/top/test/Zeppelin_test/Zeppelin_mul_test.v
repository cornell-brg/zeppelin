//========================================================================
// Zeppelin_mul_test.v
//========================================================================

`include "hw/top/test/ZeppelinTestHarness.v"
`include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"

module ZeppelinTestSuite_mul #( `ZEPPELIN_SUITE_PARAMS );
  `ZEPPELIN_SUITE_HARNESS

  `include "hw/top/test/test_cases/directed/mul_test_cases.v"
  `include "hw/top/test/test_cases/golden/mul_test_cases.v"
  `ZEPPELIN_SUITE_RUN(mul, run_golden_mul_tests();)
endmodule

module Zeppelin_mul_test;
  `define ZEPPELIN_SUITE_MODULE ZeppelinTestSuite_mul
  `include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"
endmodule
