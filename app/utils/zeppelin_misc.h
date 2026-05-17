//========================================================================
// zeppelin_misc.h
//========================================================================
// Other miscellaneous operations

#ifndef ZEPPELIN_MISC_H
#define ZEPPELIN_MISC_H

// -----------------------------------------------------------------------
// RISCV
// -----------------------------------------------------------------------

#ifdef _RISCV

#ifdef __cplusplus
extern "C" {
#endif

long zeppelin_atol( const char* str );

#ifdef __cplusplus
}
#endif

// -----------------------------------------------------------------------
// Native
// -----------------------------------------------------------------------

#else

#include <stdlib.h>
#define zeppelin_atol atol
#endif

#endif  // ZEPPELIN_MISC_H