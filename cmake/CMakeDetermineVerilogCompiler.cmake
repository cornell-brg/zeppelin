# ========================================================================
# CMakeDetermineVerilogCompiler.cmake
# ========================================================================
# Determine whether we have a Verilog compiler. Currently, only
# iverilog is supported

if(NOT DEFINED CMAKE_Verilog_COMPILER_ID)
  set(CMAKE_Verilog_COMPILER_ID "Verilator")
endif()

# ------------------------------------------------------------------------
# Verilator
# ------------------------------------------------------------------------

if(CMAKE_Verilog_COMPILER_ID STREQUAL "Verilator")
  find_program(
    CMAKE_Verilog_COMPILER 
    NAMES verilator_bin verilator_bin.exe
    DOC "Verilog compiler" 
  )
  set(CMAKE_Verilog_OUTPUT_EXTENSION .o)
  set(CMAKE_Verilog_LINKER_PREFERENCE 0) # No linker

  # Get the version and report
  execute_process(
    COMMAND ${CMAKE_Verilog_COMPILER} --version
    OUTPUT_VARIABLE VERILOG_INFO
    OUTPUT_STRIP_TRAILING_WHITESPACE
    ERROR_QUIET
  )
  message(STATUS "The Verilog compiler identification is ${VERILOG_INFO}")

  # Get the DPI includes
  execute_process(
    COMMAND ${CMAKE_Verilog_COMPILER} --getenv VERILATOR_ROOT
    OUTPUT_VARIABLE VERILATOR_ROOT
    OUTPUT_STRIP_TRAILING_WHITESPACE
    ERROR_QUIET
  )
  set(CMAKE_Verilog_DPI_INCLUDES 
    "${VERILATOR_ROOT}/include"
    "${VERILATOR_ROOT}/include/vltstd"
  )

# ------------------------------------------------------------------------
# VCS
# ------------------------------------------------------------------------

elseif(CMAKE_Verilog_COMPILER_ID STREQUAL "VCS")
  find_program(
    CMAKE_Verilog_COMPILER 
    NAMES vcs
    DOC "Verilog compiler" 
  )
  set(CMAKE_Verilog_OUTPUT_EXTENSION .v)
  set(CMAKE_Verilog_LINKER_PREFERENCE 100) # Always use our linker

  # Get the version and report
  execute_process(
    COMMAND ${CMAKE_Verilog_COMPILER} -ID
    OUTPUT_VARIABLE VERILOG_INFO
    ERROR_QUIET
  )
  string(REGEX MATCH "Compiler version = (VCS [^\t\r\n]+)" VERILOG_INFO ${VERILOG_INFO})
  message(STATUS "The Verilog compiler identification is ${CMAKE_MATCH_1}")

  # Get the DPI include path
  set(CMAKE_Verilog_DPI_INCLUDES "$ENV{VCS_HOME}/include")

# ------------------------------------------------------------------------
# Iverilog
# ------------------------------------------------------------------------

elseif(CMAKE_Verilog_COMPILER_ID STREQUAL "Iverilog")
  find_program(
    CMAKE_Verilog_COMPILER 
    NAMES iverilog
    DOC "Verilog compiler" 
  )
  set(CMAKE_Verilog_OUTPUT_EXTENSION .v)
  set(CMAKE_Verilog_LINKER_PREFERENCE 100) # Always use our linker

  execute_process(
    COMMAND ${CMAKE_Verilog_COMPILER} -V
    OUTPUT_VARIABLE VERILOG_INFO
    ERROR_QUIET
  )
  string(REGEX MATCH "Icarus Verilog [^\t\r\n]+" VERILOG_INFO ${VERILOG_INFO})
  message(STATUS "The Verilog compiler identification is ${VERILOG_INFO}")
  set(CMAKE_Verilog_DPI_INCLUDES "")

else()
  message(FATAL_ERROR "Unrecognized Verilog compiler: ${CMAKE_Verilog_COMPILER_ID}")
endif()

mark_as_advanced(CMAKE_Verilog_COMPILER)

foreach(DPI_PATH ${CMAKE_Verilog_DPI_INCLUDES})
  message(STATUS "DPI include path: ${DPI_PATH}")
endforeach()

set(CMAKE_Verilog_SOURCE_FILE_EXTENSIONS v;sv)
set(CMAKE_Verilog_COMPILER_ENV_VAR "Verilog")
set(CMAKE_Verilog_STANDARD_LIBRARIES "")
set(CMAKE_Verilog_IMPLICIT_LINK_LIBRARIES pthread)

# Configure variables set in this file for fast reload later on
configure_file(${CMAKE_CURRENT_LIST_DIR}/CMakeVerilogCompiler.cmake.in
               ${CMAKE_PLATFORM_INFO_DIR}/CMakeVerilogCompiler.cmake)