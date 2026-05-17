//========================================================================
// zeppelin_wprintf.cpp
//========================================================================
// A simple printing mechanism for Zeppelin
//
// Adapted from the printing utilities from Cornell's ECE 6745
// https://github.com/cornell-ece6745/ece6745-lab2-release/blob/main/app/ece6745/ece6745-wprint.c

#ifdef _RISCV

#include "utils/zeppelin_wprintf.h"
#include <stdarg.h>

// -----------------------------------------------------------------------
// zeppelin_wprintf_char
// -----------------------------------------------------------------------

inline void zeppelin_wprint_char( wchar_t c )
{
  volatile wchar_t* term = (wchar_t*) 0xF0000000;
  *term                  = c;
}

// -----------------------------------------------------------------------
// zeppelin_wprintf_str
// -----------------------------------------------------------------------

inline void zeppelin_wprint_str( const wchar_t* p )
{
  while ( *p != 0 ) {
    zeppelin_wprint_char( *p );
    p++;
  }
}

// -----------------------------------------------------------------------
// zeppelin_wprintf
// -----------------------------------------------------------------------

void zeppelin_wprintf( const wchar_t* fmt, ... )
{
  va_list args;
  va_start( args, fmt );

  int flag = 0;
  while ( *fmt != '\0' ) {
    if ( *fmt == '%' ) {
      flag = 1;
    }
    else if ( flag && ( *fmt == 'd' ) ) {
      int     num = va_arg( args, int );
      wchar_t buffer[20];
      int     i = 0;
      if ( num < 0 ) {
        zeppelin_wprint_char( L'-' );
        num = -num;
      }
      do {
        buffer[i] = ( num & 0xF ) + L'0';
        if ( ( num & 0xF ) > 9 ) {
          buffer[i] = ( num & 0xF ) - 10 + L'A';
        }
        num = num >> 4;
        i++;
      } while ( num > 0 );
      zeppelin_wprint_char( L'0' );
      zeppelin_wprint_char( L'x' );
      while ( i > 0 ) {
        zeppelin_wprint_char( buffer[--i] );
      }
      flag = 0;
    }
    else if ( flag && ( *fmt == 'c' ) ) {
      // note automatic conversion to integral type
      zeppelin_wprint_char( (wchar_t) ( va_arg( args, int ) ) );
      flag = 0;
    }
    else if ( flag && ( *fmt == 's' ) ) {
      zeppelin_wprint_str( va_arg( args, wchar_t* ) );
      flag = 0;
    }
    else {
      zeppelin_wprint_char( *fmt );
      flag = 0;
    }
    ++fmt;
  }
  va_end( args );
}

#endif  // _RISCV