//========================================================================
// Zeppelin_beq_test.v
//========================================================================

`include "hw/top/test/ZeppelinTestHarness.v"
`include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"

module ZeppelinTestSuite_beq #( `ZEPPELIN_SUITE_PARAMS );
  `ZEPPELIN_SUITE_HARNESS

  `include "hw/top/test/test_cases/directed/beq_test_cases.v"
  `ZEPPELIN_SUITE_RUN(beq)
endmodule

module Zeppelin_beq_test;
  `define ZEPPELIN_SUITE_MODULE ZeppelinTestSuite_beq
  `include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"
endmodule
