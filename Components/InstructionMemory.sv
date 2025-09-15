// InstructionMemory.sv
// Reads 9-bit machine code based on the Program Counter address.

module InstructionMemory (
    input  logic [11:0] Address,        
    output logic [8:0]  Instruction_out 
);

    // 12 address bits allows for4096 instructions.
    parameter MEMORY_DEPTH_BITS = 12;
    parameter MEMORY_SIZE = (1 << MEMORY_DEPTH_BITS); // Total number of instructions (4096)

    // Internal memory array to store the 9-bit instructions
    logic [8:0] core_instructions [MEMORY_SIZE-1:0];
    initial begin
        $readmemb("mach_code.txt", core_instructions);
    end

   
    assign Instruction_out = core_instructions[Address];

endmodule
