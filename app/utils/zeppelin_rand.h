//========================================================================
// zeppelin_rand.h
//========================================================================
// A software-defined RNG (not secure, but works well)

#ifndef ZEPPELIN_RAND_H
#define ZEPPELIN_RAND_H

// -----------------------------------------------------------------------
// RISCV
// -----------------------------------------------------------------------

#ifdef _RISCV

#ifdef __cplusplus
extern "C" {
#endif

int  zeppelin_rand();
void zeppelin_srand( unsigned int seed );

#ifdef __cplusplus
}
#endif

// -----------------------------------------------------------------------
// Native
// -----------------------------------------------------------------------

#else

#include <stdlib.h>
#define zeppelin_rand rand
#define zeppelin_srand srand
#endif

#endif  // ZEPPELIN_EXIT_H