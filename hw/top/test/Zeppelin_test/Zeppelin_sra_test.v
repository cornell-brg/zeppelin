//========================================================================
// Zeppelin_sra_test.v
//========================================================================

`include "hw/top/test/ZeppelinTestHarness.v"
`include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"

module ZeppelinTestSuite_sra #( `ZEPPELIN_SUITE_PARAMS );
  `ZEPPELIN_SUITE_HARNESS

  `include "hw/top/test/test_cases/directed/sra_test_cases.v"
  `ZEPPELIN_SUITE_RUN(sra)
endmodule

module Zeppelin_sra_test;
  `define ZEPPELIN_SUITE_MODULE ZeppelinTestSuite_sra
  `include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"
endmodule
