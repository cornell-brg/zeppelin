//========================================================================
// zeppelin_stdio.h
//========================================================================
// Common functions for I/O manipulation using Zeppelin's memory-mapped
// peripherals
//
// Assumes RV32I support

#ifndef ZEPPELIN_STDIO_H
#define ZEPPELIN_STDIO_H

#include <stdio.h>

// -----------------------------------------------------------------------
// RISCV
// -----------------------------------------------------------------------

#ifdef _RISCV

#ifdef __cplusplus
extern "C" {
#endif

void zeppelin_putchar( char c );
char zeppelin_getchar();

// Supported format specifiers: %c, %d, %s
//
// printf also supports basic width specifiers for %d and %s,
// using space padding
void zeppelin_printf( const char *format, ... );
int  zeppelin_sscanf( const char *input, const char *format, ... );

// Note that these differ from usual signatures, as file streams are
// not supported
int   zeppelin_fputs( const char *str );
char *zeppelin_fgets( char *str, int num );
int   zeppelin_fflush();

char zeppelin_tolower( char c );

#ifdef __cplusplus
}
#endif

// -----------------------------------------------------------------------
// Native
// -----------------------------------------------------------------------

#else

#include <ctype.h>

#define zeppelin_putchar putchar
#define zeppelin_getchar getchar

#define zeppelin_printf printf
#define zeppelin_sscanf sscanf

#define zeppelin_fputs( str ) fputs( str, stdout )
#define zeppelin_fgets( str, num ) fgets( str, num, stdin )
#define zeppelin_fflush() fflush( stdout )

#define zeppelin_tolower tolower

#endif

#endif  // ZEPPELIN_STDIO_H