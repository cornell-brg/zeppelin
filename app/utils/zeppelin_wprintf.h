//========================================================================
// zeppelin_wprintf.h
//========================================================================
// A simple printing mechanism for Zeppelin

#ifndef ZEPPELIN_WPRINTF_H
#define ZEPPELIN_WPRINTF_H

#include <wchar.h>

// -----------------------------------------------------------------------
// RISCV
// -----------------------------------------------------------------------

#ifdef _RISCV

#ifdef __cplusplus
extern "C" {
#endif

void zeppelin_wprintf( const wchar_t* fmt, ... );

#ifdef __cplusplus
}
#endif

// -----------------------------------------------------------------------
// Native
// -----------------------------------------------------------------------

#else

#define zeppelin_wprintf wprintf

#endif  // _RISCV

#endif  // ZEPPELIN_WPRINTF_H