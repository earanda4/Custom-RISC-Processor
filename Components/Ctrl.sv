// Ctrl.sv - Control Decoder Module
// Decodes 9-bit machine code into various control signals for the CPU components.

module Ctrl (
    input  logic        Clk,             // Clock (Corrected name)
    input  logic        Reset,           // Reset (Corrected name)
    input  logic        Start,           // Start (Corrected name)
    input  logic [8:0]  Instruction_in,  // 9-bit machine code from Instruction Memory (Corrected name)

    input  logic        ZeroFlag,        // Z flag from ALU
    input  logic        NegativeFlag,    // N flag from ALU

    // Register File Control Signals
    output logic [2:0]  RegReadAddr1,    // Read Address 1 (for Rs1) (Corrected width)
    output logic [2:0]  RegReadAddr2,    // Read Address 2 (for Rs2) (Corrected width)
    output logic [2:0]  RegWriteAddr,    // Write Address (for Rd) (Corrected width)
    output logic        RegWriteEnable,  // Register Write Enable
    output logic [1:0]  RegWriteData_Src_Sel, // 00: ALU_Result, 01: DMem_ReadData, 10: PC+1, 11: BX_Rm_Data (or FPU_Out)

    // ALU Control Signals
    output logic [4:0]  AluOp,           // ALU operation code
    output logic [1:0]  ALUSrcB_Sel,     // 00: RegFile_ReadData2, 01: Immediate, 10: ShiftAmount 

    // Data Memory Control Signals
    output logic        MemReadEnable,   // Data Memory Read Enable
    output logic        MemWriteEnable,  // Data Memory Write Enable
    output logic [1:0]  MemAccessWidth,  // 00: Word (32-bit), 01: Byte (8-bit) 
    // Program Counter Control Signals
    output logic        PC_Next_Sel,     // 0: PC+1, 1: Branch Target 
    output logic [4:0]  BranchOffset,    // 5-bit offset for branches (C-type)

    // Immediate & Shift Amount Values from Instruction
    output logic [1:0]  ImmediateValue,  // 2-bit immediate (I-type)
    output logic [2:0]  ShiftAmount,     // 3-bit shift amount 

    // BX Register Address
    output logic [2:0]  BX_Rm_Addr,      // 3-bit register address for BX (Rm)

    // System Control Signals
    output logic        Done             // Goes high when HALT instruction is decoded
);
    logic type_bit;    // Instruction_in[8]
    logic [2:0] opcode; // Instruction_in[7:5]
    logic [2:0] rd_rn_rs_field; // Common field for Rd, Rn, Rs, Rm (bits 4:2)
    logic [1:0] rb_imm_shift_field; // Common field for Rb, Immediate, ShiftAmount (bits 1:0)
    logic [4:0] branch_offset_field; // Common field for branch offset (bits 4:0)

    assign type_bit = Instruction_in[8];
    assign opcode   = Instruction_in[7:5];
    assign rd_rn_rs_field = Instruction_in[4:2];
    assign rb_imm_shift_field = Instruction_in[1:0];
    assign branch_offset_field = Instruction_in[4:0];

    
    always_comb begin
        RegReadAddr1       = 3'b000;  // Default to R0
        RegReadAddr2       = 3'b000;  // Default to R0
        RegWriteAddr       = 3'b000;  // Default to R0
        RegWriteEnable     = 1'b0;
        RegWriteData_Src_Sel = 2'b00; // Default to ALU result 

        AluOp              = 5'b00000; // Default to NOP/Pass-through A
        ALUSrcB_Sel        = 2'b00;   // Default to RegFile ReadData2

        MemReadEnable      = 1'b0;
        MemWriteEnable     = 1'b0;
        MemAccessWidth     = 2'b00;   // Default to Word acces

        PC_Next_Sel        = 1'b0;    // Default to PC + 1
        BranchOffset       = 5'b00000; // Default to 0
        ImmediateValue     = 2'b00;   // Default to 0
        ShiftAmount        = 3'b000;  // Default to 0 
        BX_Rm_Addr         = 3'b000;  // Default to R0

        Done               = 1'b0;    // Default to not done
        if (type_bit == 1'b0) begin // Type 0: R-type & M-type
            case (opcode)

                3'b000: begin // ORR: R-type
                    AluOp = 5'b01010; // ORR
                    RegWriteEnable = 1'b1;
                    RegWriteData_Src_Sel = 2'b00; // ALU Result
                    RegWriteAddr = Instruction_in[7:5]; // Rd
                    RegReadAddr1 = Instruction_in[1:0]; // Rn
                    RegReadAddr2 = Instruction_in[4:2]; // Rm
                    ALUSrcB_Sel = 2'b00; // Use ReadData2
                end
                3'b001: begin // LSR: R-type 
                    AluOp = 5'b01011; // LSR
                    RegWriteEnable = 1'b1;
                    RegWriteData_Src_Sel = 2'b00;
                    RegWriteAddr = Instruction_in[7:5]; // Rd
                    RegReadAddr1 = Instruction_in[1:0]; // Rn (value to shift)
                    RegReadAddr2 = Instruction_in[4:2]; // Rm (register with shift amount)
                    ALUSrcB_Sel = 2'b00; 
                end
                3'b010: begin // CMPR: R
                    AluOp = 5'b01100; // CMPR
                    RegWriteEnable = 1'b0; // No register write for CMPR
                    RegReadAddr1 = Instruction_in[1:0]; // Rn
                    RegReadAddr2 = Instruction_in[4:2]; // Rm
                    ALUSrcB_Sel = 2'b00; 
                end
                3'b100: begin 
                    RegWriteEnable = 1'b1;
                    RegWriteData_Src_Sel = 2'b01; // Data Memory Read Data
                    MemReadEnable = 1'b1;
                    MemAccessWidth = 2'b00; // Byte access
                    RegWriteAddr = rd_rn_rs_field; // Rd
                    RegReadAddr1 = 3'b000; // Base address 
                    AluOp = 5'b00001; // ADD 
                    ALUSrcB_Sel = 2'b01; // Use Immediate
                    ImmediateValue = rb_imm_shift_field; // 2-bit offset
                end
                3'b101: begin // STRB 
                    MemWriteEnable = 1'b1;
                    MemAccessWidth = 2'b00; // Byte access
                    RegReadAddr1 = rd_rn_rs_field; // Rs 
                    RegReadAddr2 = 3'b000; // R0 for address base 
                    AluOp = 5'b00001; // ADD
                    ALUSrcB_Sel = 2'b01; // Use Immediate
                    ImmediateValue = rb_imm_shift_field; // 2-bit offset
                end
                3'b110: begin 
                    RegWriteEnable = 1'b1;
                    RegWriteData_Src_Sel = 2'b01; // Data Memory Read Data
                    MemReadEnable = 1'b1;
                    MemAccessWidth = 2'b00; // Byte access
                    RegWriteAddr = rd_rn_rs_field; // Rd
                    RegReadAddr1 = 3'b000; // Base address comes from R0
                    AluOp = 5'b00001; // ADD 
                    ALUSrcB_Sel = 2'b01; // Use Immmdiate
                    ImmediateValue = rb_imm_shift_field; // 2-bit offset
                end
                3'b111: begin // STR 
                    MemWriteEnable = 1'b1;
                    MemAccessWidth = 2'b00; // Byte access
                    RegReadAddr1 = rd_rn_rs_field; // Rs
                    RegReadAddr2 = 3'b000; // R0 for address base
                    AluOp = 5'b00001; // ADD 
                    ALUSrcB_Sel = 2'b01; // Use Immediate 
                    ImmediateValue = rb_imm_shift_field; // 2-bit offset
                end
                default: begin
                end
            endcase
        end else begin 
            case (opcode)
                // I-Type Instructions: OP Rd, Imm (Rd = R0 op Imm)
             
                3'b000: begin // ADD_I: I-type, mach_code = 1_000_Rd_Imm
                    AluOp = 5'b00001; // ADD
                    RegWriteEnable = 1'b1;
                    RegWriteData_Src_Sel = 2'b00; // ALU Result
                    RegWriteAddr = rd_rn_rs_field; // Rd
                    RegReadAddr1 = 3'b000; 
                    ALUSrcB_Sel = 2'b01; // Use Immediate
                    ImmediateValue = rb_imm_shift_field;
                end
                3'b001: begin // CMP_I: I-type, mach_code = 1_001_Ra_Imm (sets flags)
                    AluOp = 5'b01001; // CMP 
                    RegWriteEnable = 1'b0; // No register write for CMP
                    RegReadAddr1 = rd_rn_rs_field; // Ra
                    ALUSrcB_Sel = 2'b01; // Use Immediate
                    ImmediateValue = rb_imm_shift_field;
                end
                3'b010: begin 
                    PC_Next_Sel = 1'b1; 
                    BranchOffset = branch_offset_field; // 5-bit signed offset
                end
                3'b011: begin // BEQ (Branch if Equal): C-type, mach_code = 1_011_BranchOffset
                    PC_Next_Sel = ZeroFlag; // Direct Branch (conditional on ZeroFlag)
                    BranchOffset = branch_offset_field;
                end
                3'b100: begin // BGE (Branch if Greater or Equal): C-type, mach_code = 1_100_BranchOffset
                    PC_Next_Sel = (NegativeFlag == ZeroFlag); // Direct Branch (conditional on N == Z)
                    BranchOffset = branch_offset_field;
                end
                3'b101: begin // JAL (Jump and Link): mach_code = 1_101_Rd (PC = Ra, Rd = PC+1) - NEWLY DEFINED
                    PC_Next_Sel = 1'b1; // Indirect Branch (PC from RegReadAddr1 in TopLevel)
                    RegWriteEnable = 1'b1;
                    RegWriteData_Src_Sel = 2'b10; // Write PC+1 to a register
                    RegWriteAddr = rd_rn_rs_field; // Rd (link register)
                    RegReadAddr1 = rd_rn_rs_field; // Ra (register containing jump target address)
                end
                3'b110: begin // LSL_I (Logical Shift Left Immediate): I-type, mach_code = 1_110_Rd_ShiftAmt (2-bit Imm)
                    AluOp = 5'b00111; // LSL (from ALU.sv)
                    RegWriteEnable = 1'b1;
                    RegWriteData_Src_Sel = 2'b00; // ALU Result
                    RegWriteAddr = rd_rn_rs_field; // Rd
                    RegReadAddr1 = rd_rn_rs_field; // Source is Rd itself (e.g., LSL Rd, #Imm)
                    ALUSrcB_Sel = 2'b10; // Use ShiftAmount input for ALU
                    ShiftAmount = {1'b0, rb_imm_shift_field}; // 2-bit immediate for shift amount, padded to 3 bits
                end
                3'b111: begin // This opcode block is shared for HALT and other potential types.
                    case(branch_offset_field) // Further decode lower 5 bits for these operations
                        5'b00000: begin // HALT instruction: 1_111_00000
                            Done = 1'b1; // Signal Done
                        end
                        5'b00100: begin // SXT: U-type, mach_code = 1_111_00100_Rd (Rd for source and dest)
                            AluOp = 5'b00100; // SXT dsa
                            RegWriteEnable = 1'b1;
                            RegWriteData_Src_Sel = 2'b00; // ALU Result
                            RegWriteAddr = rd_rn_rs_field; // Rd
                            RegReadAddr1 = rd_rn_rs_field; // Read from this register
                        end
                        5'b00101: begin // CLZ: U-type, mach_code = 1_111_00101_Rd
                            AluOp = 5'b00101; // e
                            RegWriteEnable = 1'b1;
                            RegWriteData_Src_Sel = 2'b00; // ALU Result
                            RegWriteAddr = rd_rn_rs_field;
                            RegReadAddr1 = rd_rn_rs_field;
                        end
                        5'b00011: begin // LSR_R 
                          AluOp = 5'b01011; // LSR
                            RegWriteEnable = 1'b1;
                            RegWriteData_Src_Sel = 2'b00; // ALU Result
                            RegWriteAddr = rd_rn_rs_field; // Rd
                            RegReadAddr1 = rd_rn_rs_field; // Value to shift (Rn)
                            RegReadAddr2 = {1'b0, rb_imm_shift_field}; 
                            ALUSrcB_Sel = 2'b00;
                        end
                        5'b01101: begin // FPU_CVT
                            AluOp = 5'b01101; // FPU_CVT (new ALU opcode)
                            RegWriteEnable = 1'b1;
                            RegWriteData_Src_Sel = 2'b00; // ALU Result
                            RegWriteAddr = rd_rn_rs_field; // Rd
                            RegReadAddr1 = rd_rn_rs_field; // Source of fixed-point input for conversion
                        end
                        default: begin
                        end
                    endcase
                end
                default: begin
                end
            endcase
        end
    end

endmodule
