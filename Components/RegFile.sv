// RegFile.sv


module RegFile (
    input  logic        Clk,          // Clock for synchronous writes
    input  logic        Reset,        // Added: Reset for initialization
    input  logic        WriteEnable,  // Write enable signal
    input  logic [2:0]  WriteAddr,    //3-bit address for write (0-7)
    input  logic [7:0]  WriteData,    // 8-bit data to write

    input  logic [2:0]  ReadAddr1,    // 3-bit address for read port 1
    output logic [7:0]  ReadData1,    // 8-bit data output for read port 1

    input  logic [2:0]  ReadAddr2,    // 3-bit address for read port 2
    output logic [7:0]  ReadData2     // 8-bit data output for read port 2
);

    
    (* keep *) logic [7:0] Core [0:7]; //  8 registers (0-7)

    // Synchronous write operation
    always_ff @(posedge Clk or posedge Reset) begin // Added Reset to sensitivity list
        if (Reset) begin
            // Initialize all registers to 0 on reset
            for (int i = 0; i < 8; i++) begin
                Core[i] <= 8'b0;
            end
        end else if (WriteEnable) begin
            // Register R0 (Core[0]) is typically hardwired to zero
            // so we only write if WriteAddr is not 0.
          if (WriteAddr != 3'b0) begin // 3b0 for 3-bit address
                Core[WriteAddr] <= WriteData;
            end
        end
    end

    // Asynchronous read operations
    // If ReadAddr is 0, output 0 (for R0). Otherwise, output the content of the register.
    assign ReadData1 = (ReadAddr1 == 3'b0) ? 8'b0 : Core[ReadAddr1];
    assign ReadData2 = (ReadAddr2 == 3'b0) ? 8'b0 : Core[ReadAddr2];

endmodule