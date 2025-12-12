module datapath(
    input logic        clk,
    input logic        reset,
    input logic        RegWrite,
    input logic        PCSrc,
    input logic        ResultSrc,
    input logic        MemWrite,
    input logic [2:0]  ALUControl,
    input logic        ALUSrc,
    input logic [1:0]  ImmSrc,
    input logic        RegWrite,
    input logic        ChipEnable,
    input logic [4:0]  InitAddr,
    input logic [31:0] InstrIn
)

    logic [4:0] PCNext, PC;
    logic [31:0] InstrOut, Instr;

    reg_5b PCounter(
        .clk(clk),
        .reset(reset),
        .enable(ChipEnable),
        .D(PCNext),
        .Q(PC)
    );

    sync_sram Instr_Cache(
        .clk(clk),
        .chip_enable(ChipEnable),
        .addr(PC),
        .data_out(InstrOut),
        .init_addr(InitAddr),
        .init_data(InstrIn)
    );





endmodule