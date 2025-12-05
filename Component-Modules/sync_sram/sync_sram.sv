module sync_sram (
    // Normal memory interface
    input   logic           clk,
    input   logic           chip_enable,
    input   logic           write_enable,
    input   logic [4:0]     addr,
    input   logic [31:0]    data_in,
    output  logic [31:0]    data_out,

    // Initialization interface
    input   logic           init_en,
    input   logic [4:0]     init_addr,
    input   logic [31:0]    init_data,
    input   logic           init_we
);

    logic [31:0] memory [0:31];

    always_ff @(posedge clk) begin
        // Initialization has priority
        if (init_en && init_we) begin
            memory[init_addr] <= init_data;
        end
        // Normal memory operation
        else if (chip_enable) begin
            if (write_enable) begin
                memory[addr] <= data_in;
            end
        end
    end
    
    // Combinational read (immediate)
    always_comb begin
        if (chip_enable && !write_enable) begin
            data_out = memory[addr];
        end else begin
            data_out = 'x;
        end
    end
endmodule
