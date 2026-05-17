//========================================================================
// crc32-table.cpp
//========================================================================
// CRC-32 checksum benchmark: table-lookup variant.
//
// Uses a precomputed 256-entry lookup table to process one whole byte at
// a time: one table load and one XOR per byte, with no data-dependent
// branches.  Much faster because it eliminates all the mispredicted
// branches, though it does require a table load on every iteration.

#include "utils/zeppelin_stdlib.h"
#include "ubmark_stats.h"
#include "utils/zeppelin_wprintf.h"
#include "crc32.h"

//----------------------------------------------------------------------
// table_crc -- one byte at a time, table lookup, no branches
//----------------------------------------------------------------------

__attribute__((noinline))
unsigned int table_crc( unsigned char* msg, int len, unsigned int* table )
{
  unsigned int crc = 0xFFFFFFFF;
  for ( int i = 0; i < len; i++ )
    crc = (crc >> 8) ^ table[(crc ^ msg[i]) & 0xFF];
  return crc ^ 0xFFFFFFFF;
}

//----------------------------------------------------------------------
// main
//----------------------------------------------------------------------

int main( void )
{
  int t0c = zeppelin_cycle_count();
  int t0i = zeppelin_inst_count();
  unsigned int result = table_crc( eval_msg, eval_msg_len, eval_crc_table );
  int t1c = zeppelin_cycle_count();
  int t1i = zeppelin_inst_count();

  ubmark_stats_print( "table", t1c - t0c, t1i - t0i );

  if ( result != eval_ref_crc ) {
    zeppelin_wprintf( L"\n FAILED: table CRC = %d, expected %d\n\n",
                   result, eval_ref_crc );
    zeppelin_exit( 1 );
  }
  zeppelin_wprintf( L"Results match!\n" );
}
