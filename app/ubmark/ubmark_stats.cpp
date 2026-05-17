//========================================================================
// ubmark_stats.cpp
//========================================================================
// Implementation of shared performance-reporting utilities.

#include "ubmark_stats.h"

void ubmark_stats_print( const char* variant, int cycles, int insts )
{
  int cpi_whole = cycles / insts;
  int cpi_frac  = (cycles * 100 / insts) % 100;
  zeppelin_printf( "STAT variant=%s cycles=%d insts=%d cpi=%d.%02d\n",
                variant, cycles, insts, cpi_whole, cpi_frac );
}
