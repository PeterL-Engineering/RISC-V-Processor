module sync_sram (
    // Normal memory interface
    input   logic           clk,          // Clock
    input   logic           chip_enable,  // Chip enable
    input   logic           write_enable, // Write enable
    input   logic [4:0]     addr,         // 32 entries (2^5)
    input   logic [31:0]    data_in,      // 32-bit data
    output  logic [31:0]    data_out,     // 32-bit data

    // Initialization interface
    input   logic           init_en,      // Init enable
    input   logic [4:0]     init_addr,    // Init address
    input   logic [31:0]    init_data,    // Init data
    input   logic           init_we       // Init write enable
);

    logic [31:0] memory [0:31];  // 32 entries of 32-bit data

    always_ff @(posedge clk) begin
        // Initialization has priority over normal operation
        if (init_en && init_we) begin
            memory[init_addr] <= init_data;
        end
        // Normal memory operation
        else if (chip_enable) begin
            if (write_enable) begin
                memory[addr] <= data_in;
            end
            data_out <= memory[addr];
        end
    end

endmodule