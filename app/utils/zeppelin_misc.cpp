//========================================================================
// zeppelin_misc.cpp
//========================================================================
// Other miscellaneous operations

#include "utils/zeppelin_misc.h"
#include "utils/zeppelin_string.h"

#ifdef _RISCV

//------------------------------------------------------------------------
// zeppelin_atol
//------------------------------------------------------------------------
// Inspired by Gemini

long zeppelin_atol( const char* str )
{
  long result  = 0;
  int  sign    = 1;
  bool started = false;

  if ( str == NULL ) {
    return 0;
  }

  while ( *str != '\0' ) {
    if ( zeppelin_isspace( (unsigned char) *str ) ) {
      if ( started ) {
        break;
      }
    }
    else if ( *str == '-' ) {
      if ( started ) {
        break;
      }
      sign    = -1;
      started = true;
    }
    else if ( *str == '+' ) {
      if ( started ) {
        break;
      }
      sign    = 1;
      started = true;
    }
    else if ( zeppelin_isdigit( (unsigned char) *str ) ) {
      result  = result * 10 + ( *str - '0' );
      started = true;
    }
    else {
      break;
    }
    str++;
  }

  return result * sign;
}

#endif  // _RISCV