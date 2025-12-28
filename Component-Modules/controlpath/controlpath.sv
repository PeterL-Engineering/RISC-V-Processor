module controlpath(
    input   logic        run,          // For NOP during initialization
    input   logic [6:0]  op,
    input   logic [2:0]  funct3,
    input   logic        funct7b5,
    input   logic        Zero,
    
    output  logic [1:0]  ResultSrc,
    output  logic        PCSrc, ALUSrc,
    output  logic        RegWrite, Jump,
    output  logic [1:0]  ImmSrc,
    output  logic [2:0]  ALUControl
);

    logic [1:0] ALUOp;
    logic       Branch;

    // Main Decoder
    maindec md(
        .op(op), 
        .ResultSrc(ResultSrc), 
        .MemWrite(MemWrite), 
        .Branch(Branch),
        .ALUSrc(ALUSrc), 
        .RegWrite(RegWrite), 
        .Jump(Jump), 
        .ImmSrc(ImmSrc), 
        .ALUOp(ALUOp);
    );

    // ALU Decoder
    aludec ad(
        .opb5(op[5]), 
        .funct3(funct3), 
        .funct7b5(funct7b5),
        .ALUOp(ALUOp),
        .ALUControl(ALUControl) 
        );

    assign PCSrc = Branch & Zero | Jump;

endmodule

