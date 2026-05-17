//========================================================================
// crc32-bitwise.cpp
//========================================================================
// CRC-32 checksum benchmark: bitwise variant.
//
// Processes one bit at a time: for each byte, loop 8 times, shifting
// and XOR-ing with the polynomial on each '1' bit.  This produces 8
// conditional branches per byte (2048 total), which is very costly on
// a processor with no branch predictor.

#include "utils/zeppelin_stdlib.h"
#include "ubmark_stats.h"
#include "utils/zeppelin_wprintf.h"
#include "crc32.h"

//----------------------------------------------------------------------
// bitwise_crc -- one bit at a time, branch-heavy
//----------------------------------------------------------------------

__attribute__((noinline))
unsigned int bitwise_crc( unsigned char* msg, int len )
{
  unsigned int crc = 0xFFFFFFFF;
  for ( int i = 0; i < len; i++ ) {
    crc ^= msg[i];
    for ( int j = 0; j < 8; j++ ) {
      if ( crc & 1 )
        crc = (crc >> 1) ^ eval_crc_poly;
      else
        crc >>= 1;
    }
  }
  return crc ^ 0xFFFFFFFF;
}

//----------------------------------------------------------------------
// main
//----------------------------------------------------------------------

int main( void )
{
  int t0c = zeppelin_cycle_count();
  int t0i = zeppelin_inst_count();
  unsigned int result = bitwise_crc( eval_msg, eval_msg_len );
  int t1c = zeppelin_cycle_count();
  int t1i = zeppelin_inst_count();

  ubmark_stats_print( "bitwise", t1c - t0c, t1i - t0i );

  if ( result != eval_ref_crc ) {
    zeppelin_wprintf( L"\n FAILED: bitwise CRC = %d, expected %d\n\n",
                   result, eval_ref_crc );
    zeppelin_exit( 1 );
  }
  zeppelin_wprintf( L"Results match!\n" );
}
