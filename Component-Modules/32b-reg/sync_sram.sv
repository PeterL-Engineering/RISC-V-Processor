module sync_sram #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 5
)(
    // Normal memory interface
    input   logic                     clk,          // Clock
    input   logic                     ce,           // Chip enable
    input   logic                     we,           // Write enable
    input   logic [ADDR_WIDTH-1:0]    addr,
    input   logic [ADDR_WIDTH-1:0]    data_in,
    output  logic [ADDR_WIDTH-1:0]    data_out,

    // Initialization interface
    input   logic                     init_en,      // Init enable
    input   logic [ADDR_WIDTH-1:0]    init_addr,    // Init address
    input   logic [ADDR_WIDTH-1:0]    init data,    // Init data
    input   logic                     init_we       // Init write enable
);

    logic   [DATA_WIDTH-1:0] memory [0:(1<<ADDR_WIDTH)-1];

    always_ff @(posedge clk) begin
        // Initialization has priority over normal operation
        if (init_en && init_we) begin
            memory[init_addr] <= init_data;
        end

        // Normal memory operation
        else if (ce) begin
            if (we) begin
                memory[addr] <= data_in;
            end
            data_out <= memory[addr];
        end
    end

endmodule