//========================================================================
// stringsearch-byte.cpp
//========================================================================
// Substring search benchmark: byte-by-byte variant.
//
// Reads one character at a time using byte loads (lbu), comparing
// character by character.  Each mismatch causes a branch, and on a
// processor with no branch predictor every early-exit branch is costly.

#include "utils/zeppelin_stdlib.h"
#include "ubmark_stats.h"
#include "utils/zeppelin_wprintf.h"
#include "stringsearch.h"

//----------------------------------------------------------------------
// byte_search -- naive byte-by-byte comparison
//----------------------------------------------------------------------

__attribute__((noinline))
int byte_search( const char* text, int text_len,
                 const char* pattern, int pat_len )
{
  int count = 0;
  int limit = text_len - pat_len;
  for ( int i = 0; i <= limit; i++ ) {
    int match = 1;
    for ( int j = 0; j < pat_len; j++ ) {
      if ( text[i + j] != pattern[j] ) {
        match = 0;
        break;
      }
    }
    count += match;
  }
  return count;
}

//----------------------------------------------------------------------
// main
//----------------------------------------------------------------------

int main( void )
{
  int t0c = zeppelin_cycle_count();
  int t0i = zeppelin_inst_count();
  int result = byte_search( eval_text, eval_text_len,
                            eval_pattern, eval_pattern_len );
  int t1c = zeppelin_cycle_count();
  int t1i = zeppelin_inst_count();

  ubmark_stats_print( "byte", t1c - t0c, t1i - t0i );

  if ( result != eval_ref_count ) {
    zeppelin_wprintf( L"\n FAILED: byte count = %d, expected %d\n\n",
                   result, eval_ref_count );
    zeppelin_exit( 1 );
  }
  zeppelin_wprintf( L"Results match!\n" );
}
