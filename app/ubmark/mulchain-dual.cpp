//========================================================================
// mulchain-dual.cpp
//========================================================================
// Multiply-chain microbenchmark: dual-chain variant.
//
// Evaluates two independent polynomials (different coefficients) in an
// interleaved loop via Horner's method on 64 data points.  The two
// chains can issue to both MUL pipes simultaneously via OOO issue.

#include "utils/zeppelin_stdlib.h"
#include "ubmark_stats.h"
#include "utils/zeppelin_wprintf.h"
#include "mulchain.h"

//----------------------------------------------------------------------
// horner_dual -- evaluate two polynomials interleaved, sum each
//----------------------------------------------------------------------

__attribute__((noinline))
void horner_dual( int* coeff_a, int* coeff_b, int* x, int n, int deg,
                  int* sum_a, int* sum_b )
{
  int sa = 0, sb = 0;
  for ( int i = 0; i < n; i++ ) {
    int va = coeff_a[deg - 1];
    int vb = coeff_b[deg - 1];
    for ( int d = deg - 2; d >= 0; d-- ) {
      va = va * x[i] + coeff_a[d];
      vb = vb * x[i] + coeff_b[d];
    }
    sa += va;
    sb += vb;
  }
  *sum_a = sa;
  *sum_b = sb;
}

//----------------------------------------------------------------------
// main
//----------------------------------------------------------------------

int main( void )
{
  int dual_a, dual_b;
  int t0c = zeppelin_cycle_count();
  int t0i = zeppelin_inst_count();
  horner_dual( eval_coeff_a, eval_coeff_b, eval_x, eval_size, eval_degree,
               &dual_a, &dual_b );
  int t1c = zeppelin_cycle_count();
  int t1i = zeppelin_inst_count();

  ubmark_stats_print( "dual", t1c - t0c, t1i - t0i );

  if ( dual_a != eval_ref_a ) {
    zeppelin_wprintf( L"\n FAILED: dual poly_a = %d, expected %d\n\n",
                   dual_a, eval_ref_a );
    zeppelin_exit( 1 );
  }
  if ( dual_b != eval_ref_b ) {
    zeppelin_wprintf( L"\n FAILED: dual poly_b = %d, expected %d\n\n",
                   dual_b, eval_ref_b );
    zeppelin_exit( 1 );
  }
  zeppelin_wprintf( L"Results match!\n" );
}
