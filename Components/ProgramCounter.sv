// ProgramCounter.sv - Program Counter

module ProgramCounter (
    input  logic         Clk,           // System clock
    input  logic         Reset,         // Asynchronous reset (active high)
    input  logic         PC_Enable, 

    // Control signal from the Control Decoder
    input  logic         PC_Next_Sel,   // Selects source for next PC:
                                        // 0: PC + 1 (sequential)
                                        // 1: Branch Target (from BranchTarget_in)

    // Data input for branch targets
    input  logic [11:0]  BranchTarget_in,  // Target address for branch

  	output logic [11:0]  PC_out          // Th value
);

    // Internal wire for the next PC value before assignment
    logic [11:0] next_pc_value;

    // Logic to determine the next PC value based on control signals
    always_comb begin
        if (PC_Next_Sel == 1'b1) begin // If PC_Next_Sel is high, take the branch target
            next_pc_value = BranchTarget_in;
        end else begin // Otherwise, increment sequentially
            next_pc_value = PC_out + 12'd1;
        end
    end

    // The PC  only updates if PC_Enable is high and not in reset.
    always_ff @(posedge Clk or posedge Reset) begin // Asynchronous reset
        if (Reset) begin
            PC_out <= 12'b0; // Reset PC to 0
        end else if (PC_Enable) begin
            PC_out <= next_pc_value;
        end
    end

endmodule
