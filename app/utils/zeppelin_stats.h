//========================================================================
// zeppelin_stats.h
//========================================================================
// Utilities for reporting processor statistics

#ifndef ZEPPELIN_STATS_H
#define ZEPPELIN_STATS_H

// -----------------------------------------------------------------------
// RISCV
// -----------------------------------------------------------------------

#ifdef _RISCV

#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>
uint32_t zeppelin_cycle_count();
uint32_t zeppelin_inst_count();

#ifdef __cplusplus
}
#endif

// -----------------------------------------------------------------------
// Native
// -----------------------------------------------------------------------

#else

// No strict notion of cycles or instructions
#define zeppelin_cycle_count() 0
#define zeppelin_inst_count()  0

#endif

#endif  // ZEPPELIN_STATS_H