//========================================================================
// TraceHeader.v
//========================================================================
// Shared helper for building fixed-width module-name header strings used
// by the per-module `trace_header(trace_level)` functions. The macro is
// included inside each module's `ifndef SYNTHESIS` block so the helper is
// local to the module.

`ifndef HW_UTIL_TRACE_HEADER_V
`define HW_UTIL_TRACE_HEADER_V

`ifndef SYNTHESIS

// Defines a function `th_pad(name, width)` returning a string exactly
// `width` characters long: left-justified `name` padded/truncated to fit.
`define TRACE_HEADER_PAD_FN                                                \
  function automatic string th_pad( string name, int width );              \
    th_pad = name;                                                         \
    while( th_pad.len() < width )                                          \
      th_pad = {th_pad, " "};                                              \
    if( th_pad.len() > width )                                             \
      th_pad = th_pad.substr( 0, width - 1 );                              \
  endfunction

// Defines a function `ts_str(width)` returning a string of `width` `#`
// characters, used as the stall body in trace lanes so its width matches
// the hex sequence-number width.
`define TRACE_STALL_FN                                                     \
  function automatic string ts_str( int width );                           \
    ts_str = "";                                                           \
    while( ts_str.len() < width )                                          \
      ts_str = {ts_str, "#"};                                              \
  endfunction

`endif

`endif // HW_UTIL_TRACE_HEADER_V
