//========================================================================
// Zeppelin_mixed_test.v
//========================================================================

`include "hw/top/test/ZeppelinTestHarness.v"
`include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"

module ZeppelinTestSuite_mixed #( `ZEPPELIN_SUITE_PARAMS );
  `ZEPPELIN_SUITE_HARNESS

  `include "hw/top/test/test_cases/directed/mixed_test_cases.v"
  `include "hw/top/test/test_cases/golden/mixed_test_cases.v"
  `ZEPPELIN_SUITE_RUN(mixed, run_golden_mixed_tests();)
endmodule

module Zeppelin_mixed_test;
  `define ZEPPELIN_SUITE_MODULE ZeppelinTestSuite_mixed
  `include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"
endmodule
