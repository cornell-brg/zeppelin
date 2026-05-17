//========================================================================
// ubmark_stats.h
//========================================================================
// Shared performance-reporting utilities for microbenchmarks.
//
// Provides helpers to measure and print cycle/instruction counts in a
// structured format that is both human-readable and easy to parse with
// a script.
//
// Output format (one line per measured region):
//   STAT variant=<name> cycles=<N> insts=<N> cpi=<W>.<FF>
//
// Python one-liner to extract all stats from simulator output:
//   import re
//   stats = [m.groupdict() for m in
//            re.finditer(r'STAT variant=(?P<variant>\S+) '
//                        r'cycles=(?P<cycles>\d+) '
//                        r'insts=(?P<insts>\d+) '
//                        r'cpi=(?P<cpi>\S+)', text)]

#ifndef APP_UBMARK_UBMARK_STATS_H
#define APP_UBMARK_UBMARK_STATS_H

#include "utils/zeppelin_stdlib.h"
#include "utils/zeppelin_stdio.h"

//----------------------------------------------------------------------
// ubmark_stats_print
//----------------------------------------------------------------------
// Print a single STAT line for the given variant name and measured
// cycle/instruction counts.

void ubmark_stats_print( const char* variant, int cycles, int insts );

#endif // APP_UBMARK_UBMARK_STATS_H
