//========================================================================
// Zeppelin_divu_test.v
//========================================================================

`include "hw/top/test/ZeppelinTestHarness.v"
`include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"

module ZeppelinTestSuite_divu #( `ZEPPELIN_SUITE_PARAMS );
  `ZEPPELIN_SUITE_HARNESS

  `include "hw/top/test/test_cases/directed/divu_test_cases.v"
  `ZEPPELIN_SUITE_RUN(divu)
endmodule

module Zeppelin_divu_test;
  `define ZEPPELIN_SUITE_MODULE ZeppelinTestSuite_divu
  `include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"
endmodule
