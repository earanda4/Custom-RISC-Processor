// Mux2_to_1_32bit.sv - 2-to-1 Multiplexer for 8bit data

module Mux2_to_1_32bit (
    input  logic        sel,  // Selection input (0: in0, 1: in1)
  input  logic [7:0] in0,  // Data input 0
  input  logic [7:0] in1,  // Data input 1
  output logic [7:0] out   // Selected output
);

    // Combinational logic for the multiplexer
    assign out = sel ? in1 : in0;

endmodule