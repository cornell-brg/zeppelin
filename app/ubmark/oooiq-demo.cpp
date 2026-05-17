//========================================================================
// oooiq-demo.cpp
//========================================================================
// Demonstrates the benefit of the out-of-order issue queue
// (P_ALL_IQ_IN_ORDER=0) over the in-order issue queue (=1) on Zeppelin.
//
// Per outer iteration:
//   1. One iterative DIV produces t0 (long-latency).
//   2. Four ADDs consume t0 -- one per ALU pipe via iSLIP. Each becomes
//      the head of its IQ and stalls until the div completes.
//   3. Twelve independent ADDs that don't read t0. Each writes a
//      distinct logical destination so they don't WAW-serialize at the
//      rename table (SSRenameTableL3 enforces one outstanding rename per
//      areg via entry_still_pend / is_dup_areg).
//
// With OOO IQ, the 12 independents issue past the 4 stalled deps in
// each ALU pipe's IQ. With in-order IQ, the IQs fill behind the stalled
// heads and dispatch backpressures until the div completes.

#include <stdint.h>
#include "utils/zeppelin_stats.h"
#include "utils/zeppelin_wprintf.h"
#include "ubmark_stats.h"

__attribute__((noinline))
int oooiq_kernel( int dividend, int divisor, int iters )
{
  // Pin inputs to a0/a1 so the kernel asm can reference them by name.
  register int dvd asm("a0") = dividend;
  register int dvr asm("a1") = divisor;
  register int it  asm("a2") = iters;
  register int out asm("t4");

  asm volatile (
    // Source operand pool -- written once, read by every iteration's
    // independents. These rename once, become non-pending, then all
    // independents that read them are issue-queue-ready immediately.
    "li   a3,  17                 \n\t"
    "li   a4,  34                 \n\t"
    "li   a5,  51                 \n\t"
    "li   a6,  68                 \n\t"
    "li   a7,  85                 \n\t"
    "li   s0, 102                 \n\t"

    "1:                           \n\t"

    // 1 long-latency producer of t0
    "div  t0, a0, a1              \n\t"

    // 4 dependents on t0 -- distinct dests so they all rename in one
    // cycle. Each lands at the head of one ALU pipe's IQ and stalls.
    "add  t1, t0, a3              \n\t"
    "add  t2, t0, a4              \n\t"
    "add  t3, t0, a5              \n\t"
    "add  t4, t0, a6              \n\t"

    // 12 independents -- 12 distinct dests, all source operands ready.
    // With OOO IQ, these issue while t1..t4 wait for div. With
    // in-order IQ, they sit behind t1..t4 in their ALU pipes' IQs.
    "add  s1, a3, a4              \n\t"
    "add  s2, a5, a6              \n\t"
    "add  s3, a7, s0              \n\t"
    "add  s4, a3, a5              \n\t"
    "add  s5, a4, a6              \n\t"
    "add  s6, a5, a7              \n\t"
    "add  s7, a6, s0              \n\t"
    "add  s8, a3, a6              \n\t"
    "add  s9, a4, a7              \n\t"
    "add  s10,a5, s0              \n\t"
    "add  s11,a3, a7              \n\t"
    "add  t5, a4, s0              \n\t"

    "addi a2, a2, -1              \n\t"
    "bnez a2, 1b                  \n\t"

    : "+r"(it), "=r"(out)
    : "r"(dvd), "r"(dvr)
    : "a3","a4","a5","a6","a7","s0","s1","s2","s3","s4","s5","s6",
      "s7","s8","s9","s10","s11","t0","t1","t2","t3","t5","memory"
  );

  return out;
}

int main( void )
{
  int t0c = zeppelin_cycle_count();
  int t0i = zeppelin_inst_count();
  volatile int result = oooiq_kernel( 1234567, 7, 32 );
  int t1c = zeppelin_cycle_count();
  int t1i = zeppelin_inst_count();

  ubmark_stats_print( "oooiq-demo", t1c - t0c, t1i - t0i );
  zeppelin_wprintf( L"result=%d\n", result );
  return 0;
}
