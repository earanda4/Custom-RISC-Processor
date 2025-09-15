// Mux4_to_1_32bit.sv - 4-to-1 Multiplexer for 8-bit data

module Mux4_to_1_32bit (
    input  logic [1:0]  sel,  // 2-bit Selection input
  input  logic [7:0] in0,  // Data input 0 (select = 2'b00)
  input  logic [7:0] in1,  // Data input 1 (select = 2'b01)
  input  logic [7:0] in2,  // Data input 2 (select = 2'b10)
  input  logic [7:0] in3,  // Data input 3 (select = 2'b11)
  output logic [7:0] out   // Selected output
);

    // Combinational logic for the multiplexer
    always_comb begin
        case (sel)
            2'b00: out = in0;
            2'b01: out = in1;
            2'b10: out = in2;
            2'b11: out = in3;
            default: out = '0; 
        endcase
    end

endmodule