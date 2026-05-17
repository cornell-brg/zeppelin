//========================================================================
// regpress-high.cpp
//========================================================================
// Register-pressure microbenchmark: high-pressure variant.
//
// 16 independent accumulators.  Despite having more ILP available, the
// large number of live registers may exhaust the physical register file,
// causing rename stalls that throttle dispatch.

#include "utils/zeppelin_stdlib.h"
#include "utils/zeppelin_wprintf.h"
#include "ubmark_stats.h"
#include "regpress.h"

//----------------------------------------------------------------------
// high_pressure -- 16 accumulators
//----------------------------------------------------------------------

__attribute__((noinline))
void high_pressure( int* data, int n,
                    int* r0,  int* r1,  int* r2,  int* r3,
                    int* r4,  int* r5,  int* r6,  int* r7,
                    int* r8,  int* r9,  int* r10, int* r11,
                    int* r12, int* r13, int* r14, int* r15 )
{
  int a0 = 0, a1 = 0, a2 = 0, a3 = 0;
  int a4 = 0, a5 = 0, a6 = 0, a7 = 0;
  int a8 = 0, a9 = 0, a10 = 0, a11 = 0;
  int a12 = 0, a13 = 0, a14 = 0, a15 = 0;
  for ( int i = 0; i < n; i++ ) {
    int v = data[i];
    a0  += v;
    a1  ^= v;
    a2  += v * v;
    a3  -= v;
    a4  += v << 1;
    a5  ^= v + 1;
    a6  += v + 5;
    a7  -= v >> 1;
    a8  += v;
    a9  ^= v;
    a10 += v * v;
    a11 -= v;
    a12 += v << 1;
    a13 ^= v + 1;
    a14 += v + 5;
    a15 -= v >> 1;
  }
  *r0 = a0; *r1 = a1; *r2 = a2; *r3 = a3;
  *r4 = a4; *r5 = a5; *r6 = a6; *r7 = a7;
  *r8 = a8; *r9 = a9; *r10 = a10; *r11 = a11;
  *r12 = a12; *r13 = a13; *r14 = a14; *r15 = a15;
}

//----------------------------------------------------------------------
// main
//----------------------------------------------------------------------

int main( void )
{
  int h0, h1, h2, h3, h4, h5, h6, h7;
  int h8, h9, h10, h11, h12, h13, h14, h15;
  int t0c = zeppelin_cycle_count();
  int t0i = zeppelin_inst_count();
  high_pressure( eval_data, eval_size,
                 &h0, &h1, &h2, &h3, &h4, &h5, &h6, &h7,
                 &h8, &h9, &h10, &h11, &h12, &h13, &h14, &h15 );
  int t1c = zeppelin_cycle_count();
  int t1i = zeppelin_inst_count();

  ubmark_stats_print( "high-pressure", t1c - t0c, t1i - t0i );

  if ( h0 != eval_ref_hi_a0 || h1 != eval_ref_hi_a1 ||
       h2 != eval_ref_hi_a2 || h3 != eval_ref_hi_a3 ||
       h4 != eval_ref_hi_a4 || h5 != eval_ref_hi_a5 ||
       h6 != eval_ref_hi_a6 || h7 != eval_ref_hi_a7 ) {
    zeppelin_wprintf( L"\n FAILED: high a0-a7\n" );
    zeppelin_exit( 1 );
  }
  if ( h8 != eval_ref_hi_a0 || h9 != eval_ref_hi_a1 ||
       h10 != eval_ref_hi_a2 || h11 != eval_ref_hi_a3 ||
       h12 != eval_ref_hi_a4 || h13 != eval_ref_hi_a5 ||
       h14 != eval_ref_hi_a6 || h15 != eval_ref_hi_a7 ) {
    zeppelin_wprintf( L"\n FAILED: high a8-a15\n" );
    zeppelin_exit( 1 );
  }
  zeppelin_wprintf( L"Results match!\n" );
}
