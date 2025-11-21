module reg_file(
    input  logic           clk,
    input  logic           WE3,    // Reg write enable
    input  logic  [4:0]    A1,     // INSTR [19:15]
    input  logic  [4:0]    A2,     // INSTR [24:20]
    input  logic  [4:0]    A3,     // INSTR [11:7]
    input  logic  [31:0]   WD,     // Write data
    
    output logic  [31:0]   RD1,
    output logic  [31:0]   RD2
);

endmodule