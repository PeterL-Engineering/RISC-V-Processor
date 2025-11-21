module data_mem(
    input   logic           clk,
    input   logic           reset,
    input   logic           write_enable,
    input   logic [31:0]    A,      // Memory address (byte address)
    input   logic [31:0]    WD,     // Write data (32-bit)
    output  logic [31:0]    RD      // Read data (32-bit)
);

    // Data memory - 32 words (128 bytes) of 32 bits each
    // Using word addressing (each address = 4 bytes)
    logic [31:0] data [0:31];

    // Convert byte address to word address (divide by 4)
    logic [4:0] word_addr;
    assign word_addr = A[6:2];  // Use bits [6:2] for word addressing (32 words)

    // Write operation (synchronous)
    always_ff @(posedge clk) begin
        if (reset) begin
            // Reset ALL memory locations to zero
            for (int i = 0; i < 32; i++) begin
                data[i] <= 32'b0;
            end
        end
        else if (write_enable) begin
            // Only write if address is within bounds
            if (A[31:7] == 25'b0) begin  // Check that upper bits are zero
                data[word_addr] <= WD;
            end
        end
    end

    // Read operation (combinational)
    assign RD = (A[31:7] == 25'b0) ? data[word_addr] : 32'b0;

endmodule