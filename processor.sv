module singleProcessor(
    input   logic             clk, reset, run,
    input   logic   [31:0]    Instr,
    input   logic   [31:0]    ReadData,

    output  logic   [31:0]    PC,      
    output  logic   [31:0]    ALUResult, WriteData,
);

    logic       ALUSrc, RegWrite, Jump, Zero;
    logic [1:0] ResultSrc, ImmSrc;
    logic [2:0] ALUControl;

    controlpath c(
        .run(run),
        .op(Instr[6:0]),
        .funct3(Instr[14:12]),
        .funct7b5(Instr[30]),
        .Zero(Zero),
        .ResultSrc(ResultSrc),
        .PCSrc(PCSrc),
        .ALUSrc(ALUSrc),
        .RegWrite(RegWrite),
        .Jump(Jump),
        .ImmSrc(ImmSrc),
        .ALUControl(ALUControl)
    );

    datapath dp(
        .clk(clk),
        .reset(reset),
        .RegWrite(RegWrite),
        .PCSrc(PCSrc),
        .ResultSrc(ResultSrc),
        .MemWrite(MemWrite),
        .ALUControl(ALUControl),
        .ALUSrc(ALUSrc),
        .ImmSrc(ImmSrc),
        .RegWrite(RegWrite),
        .ChipEnable(run),
        .InitAddr,
        .InstrIn,
        .Result
    );

endmodule