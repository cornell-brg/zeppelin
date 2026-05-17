//========================================================================
// echo.cpp
//========================================================================
// Echo back user input to test our IO functions

#include "utils/zeppelin_stdio.h"
#include <stdio.h>

int main()
{
  zeppelin_fputs( "Enter a string: " );

  char buffer[20];
  zeppelin_fgets( buffer, 20 );
  zeppelin_printf( "Received string: %s", buffer );

  zeppelin_printf( "Enter an integer (such as %d), then a string: ", 20 );

  zeppelin_fgets( buffer, 20 );
  int num;
  int conversions = zeppelin_sscanf( buffer, "%d %s", &num, buffer );
  zeppelin_printf( "Received integer: %d\n", num );
  zeppelin_printf( "Received string: %s\n", buffer );
  zeppelin_printf( "Number of conversions: %d\n", conversions );
  return 0;
}