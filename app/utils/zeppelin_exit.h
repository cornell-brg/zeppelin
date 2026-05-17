//========================================================================
// zeppelin_exit.h
//========================================================================
// A mechanism for Zeppelin to signal to exit

#ifndef ZEPPELIN_EXIT_H
#define ZEPPELIN_EXIT_H

// -----------------------------------------------------------------------
// RISCV
// -----------------------------------------------------------------------

#ifdef _RISCV

#ifdef __cplusplus
extern "C" {
#endif

void zeppelin_exit( int exit_code );

#ifdef __cplusplus
}
#endif

// -----------------------------------------------------------------------
// Native
// -----------------------------------------------------------------------

#else

#include <stdlib.h>
#define zeppelin_exit exit
#endif

#endif  // ZEPPELIN_EXIT_H