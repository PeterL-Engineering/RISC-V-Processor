module sync_sram (
    // Normal memory interface
    input   logic           clk,
    input   logic           chip_enable,
    input   logic [4:0]     addr,
    output  logic [31:0]    data_out,

    // Initialization interface
    input   logic [4:0]     init_addr,
    input   logic [31:0]    init_data,
);

    logic [31:0] memory [0:31];

    always_ff @(posedge clk) begin
        // Initialization
        if (!chip_enable) begin
            memory[init_addr] <= init_data;
        end
    end
    
    // Combinational read (immediate)
    always_comb begin
        if (chip_enable) begin
            data_out = memory[addr];
        end else begin
            data_out = 'x;
        end
    end
endmodule
