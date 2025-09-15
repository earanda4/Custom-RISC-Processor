// ALU.sv
// Simple 8-bit Arithmetic Logic Unit
// Performs various operations and sets condition flags.

module ALU (
    input  logic [4:0]  AluOp,        // 5-bit ALU operation code
    input  logic [7:0]  OperandA,     // 8-bit operand A (from RegFile, PC, etc.)
    input  logic [7:0]  OperandB,     // 8-bit operand B (from RegFile, Immediate, etc.)
    input  logic [2:0]  ShiftAmount,  // Explicit input for shift amount (if not from OperandB)

    output logic [7:0]  Result,       // 8-bit result
    output logic        ZeroFlag,     // Z flag
    output logic        NegativeFlag, // N flag
    output logic        CarryFlag,    // C flag
    output logic        OverflowFlag  // V flag
);

    logic [8:0] temp_result_9bit;

    // Main ALU case 
    always_comb begin
        Result = 8'b0;
        ZeroFlag = 1'b0;
        NegativeFlag = 1'b0;
        CarryFlag = 1'b0;
        OverflowFlag = 1'b0;

        case (AluOp)
            // 5'b00000: Pass-through A (for MOV, LDR/STR address calc)
            5'b00000: Result = OperandA;

            // Arithmetic Operations
            5'b00001: begin // ADD (OperandA + OperandB)
                temp_result_9bit = {1'b0, OperandA} + {1'b0, OperandB};
                Result = temp_result_9bit[7:0];
                CarryFlag = temp_result_9bit[8]; // Carry out of MSB
                OverflowFlag = ((OperandA[7] == OperandB[7]) && (Result[7] != OperandA[7]));
            end
            5'b00010: begin // SUB (OperandA - OperandB)
                temp_result_9bit = {1'b0, OperandA} - {1'b0, OperandB};
                Result = temp_result_9bit[7:0];
                CarryFlag = ~temp_result_9bit[8];
                OverflowFlag = ((OperandA[7] != OperandB[7]) && (Result[7] != OperandA[7]));
            end
            5'b00011: begin // RSB (OperandB - OperandA)
                temp_result_9bit = {1'b0, OperandB} - {1'b0, OperandA};
                Result = temp_result_9bit[7:0];
                CarryFlag = ~temp_result_9bit[8]; // Carry for subtraction (borrow)
                // Overflow for 8-bit signed subtraction: (B_sign != A_sign) && (Result_sign != B_sign)
                OverflowFlag = ((OperandB[7] != OperandA[7]) && (Result[7] != OperandB[7]));
            end

            5'b00100: begin 
                Result = OperandA;
            end
            5'b00101: begin // CLZ (Count Leading Zeros - for 8-bit)
                if (OperandA == 8'b0) Result = 8'd8; // All zeros
                else if (OperandA[7]) Result = 8'd0;
                else if (OperandA[6]) Result = 8'd1;
                else if (OperandA[5]) Result = 8'd2;
                else if (OperandA[4]) Result = 8'd3;
                else if (OperandA[3]) Result = 8'd4;
                else if (OperandA[2]) Result = 8'd5;
                else if (OperandA[1]) Result = 8'd6;
                else Result = 8'd7; // Only bit 0 is 1
            end

            // Logical Operations
            5'b00110: Result = OperandA & OperandB; // AND
            5'b01010: Result = OperandA | OperandB; // ORR

            // Shift Operations
            5'b00111: Result = OperandA << ShiftAmount; // LSL 
            5'b01000: Result = OperandA >> ShiftAmount; // LSRI 
            5'b01011: Result = OperandA >> OperandB[2:0]; // LSR 
                                                         

            // Compare 
            5'b01001: begin // CMP (OperandA - OperandB) - for CMP Rd, #Imm
                temp_result_9bit = {1'b0, OperandA} - {1'b0, OperandB};
                Result = temp_result_9bit[7:0]; // Result
                CarryFlag = ~temp_result_9bit[8];
                OverflowFlag = ((OperandA[7] != OperandB[7]) && (Result[7] != OperandA[7]));
            end
            5'b01100: begin // CMPR (OperandA - OperandB) - for CMPR Rn, Rm
                temp_result_9bit = {1'b0, OperandA} - {1'b0, OperandB};
                Result = temp_result_9bit[7:0]; // Result 
                CarryFlag = ~temp_result_9bit[8];
                OverflowFlag = ((OperandA[7] != OperandB[7]) && (Result[7] != OperandA[7]));
            end

            default: Result = 8'b0; 
        endcase

        // General flag setting (applies to all operations where meaningful)
        ZeroFlag = (Result == 8'b0);
        NegativeFlag = Result[7]; // MSB indicates negative for signed numbers
    end

endmodule
