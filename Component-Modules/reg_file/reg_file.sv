module reg_file(
    input   logic           clk,
    input   logic           reset,  
    input   logic           write_enable,
    input   logic  [4:0]    A1,     // Read address 1 (rs1)
    input   logic  [4:0]    A2,     // Read address 2 (rs2) 
    input   logic  [4:0]    A3,     // Write address (rd)
    input   logic  [31:0]   WD,     // Write data
    
    output  logic  [31:0]   RD1,    // Read data 1
    output  logic  [31:0]   RD2     // Read data 2
);

    // Register file - 32 registers of 32 bits each
    logic [31:0] registers [0:31];

    // Write operation (synchronous)
    always_ff @(posedge clk) begin
        if (reset) begin
            // Reset ALL registers to zero (except x0 which is always zero)
            for (int i = 0; i < 32; i++) begin
                registers[i] <= 32'b0;
            end
        end else if (write_enable && A3 != 5'b0) begin
            // Write to register (but never write to x0)
            registers[A3] <= WD;
        end
    end

    // Read operations (combinational/asynchronous)
    assign RD1 = (A1 == 5'b0) ? 32'b0 : registers[A1];  // x0 always returns 0
    assign RD2 = (A2 == 5'b0) ? 32'b0 : registers[A2];  // x0 always returns 0

endmodule