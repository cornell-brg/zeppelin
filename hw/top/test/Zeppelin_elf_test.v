//========================================================================
// Zeppelin_elf_test.v
//========================================================================

`include "hw/top/test/ZeppelinTestHarness.v"

module Zeppelin_elf_test();
  ZeppelinTestHarness h();

  string elf_file;

  initial begin
    test_bench_begin( `__FILE__ );

    h.t.timeout = 1000000;
    if( !$value$plusargs( "elf=%s", elf_file ) )
      $fatal(0, "No ELF file specified with +elf=/path/to/elf" );

    h.t.test_case_begin( $sformatf( "%s", elf_file ) );
    h.load_elf( elf_file );
    h.check_traces();
    h.t.test_case_end();

    test_bench_end();
  end
endmodule
