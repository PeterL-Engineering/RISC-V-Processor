module controlpath(
    input logic clk,
    input logic reset,
    input logic run,
    input logic zero,
    input logic [31:0] INSTRin,
    output logic PCSrc,
    output logic ResultSrc,
    output logic MemWrite,
    output logic [2:0] ALUControl,
    output logic ALUSrc,
    output logic [1:0] ImmSrc,
    output logic RegWrite
);

endmodule

