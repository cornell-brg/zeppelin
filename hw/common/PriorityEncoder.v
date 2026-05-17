//========================================================================
// PriorityEncoder.v
//========================================================================
// A general-purpose priority encoder, which prioritizes lower-index
// inputs

`ifndef HW_COMMON_PRIORITY_ENCODER_V
`define HW_COMMON_PRIORITY_ENCODER_V

module PriorityEncoder #(
  parameter p_width = 2
)(
  input  logic [p_width-1:0] in,
  output logic [p_width-1:0] out
);

  generate

    //--------------------------------------------------------------------
    // Trivial case
    //--------------------------------------------------------------------
    
    if( p_width == 1 )
      assign out = in;

    //--------------------------------------------------------------------
    // General case
    //--------------------------------------------------------------------

    else begin

      logic [p_width-1:0] out_split /* verilator split_var */;

      genvar i;
      for( i = 0; i < p_width; i = i + 1 ) begin: detector
        if( i == 0 )
          assign out_split[i] = in[i];
        else
          assign out_split[i] = in[i] & !(|out_split[i-1:0]);
  
        assign out[i] = out_split[i];
      end
    end
  endgenerate
endmodule

`endif // HW_COMMON_PRIORITY_ENCODER_V
