//========================================================================
// zeppelin_string.h
//========================================================================
// Common string operations

#ifndef ZEPPELIN_STRING_H
#define ZEPPELIN_STRING_H

// -----------------------------------------------------------------------
// RISCV
// -----------------------------------------------------------------------

#ifdef _RISCV

#include <stdbool.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

void*  zeppelin_memset( void* dest, int val, size_t len );
size_t zeppelin_strlen( const char* str );
void   zeppelin_strcpy( char* dest, const char* src );
int    zeppelin_strcmp( const char* s1, const char* s2 );
char*  zeppelin_strrchr( const char* str, int c );
bool   zeppelin_isdigit( char c );
bool   zeppelin_isspace( char c );

#ifdef __cplusplus
}
#endif

// -----------------------------------------------------------------------
// Native
// -----------------------------------------------------------------------

#else

#include <ctype.h>
#include <string.h>
#define zeppelin_memset memset
#define zeppelin_strlen strlen
#define zeppelin_strcpy strcpy
#define zeppelin_strcmp strcmp
#define zeppelin_strrchr strrchr
#define zeppelin_isdigit isdigit
#define zeppelin_isspace isspace
#endif

#endif  // ZEPPELIN_EXIT_H