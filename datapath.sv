module datapath(
    input logic        clk,
    input logic        reset,
    input logic        RegWrite,
    input logic        PCSrc,
    input logic [1:0]  ResultSrc,
    input logic        MemWrite,
    input logic [2:0]  ALUControl,
    input logic        ALUSrc,
    input logic [1:0]  ImmSrc,
    input logic        RegWrite,
    input logic        ChipEnable,
    input logic [4:0]  InitAddr,
    input logic [31:0] InstrIn,

    output logic [31:0] Result
)

    logic [4:0]  PCNext, PCPlus4, PCTarget, PC;
    logic [31:0] InstrOut, Instr, NOP;
    logic [31:0] SrcA, SrcB, WriteData, ImmExt;
    logic [31:0] ALUResult, ReadData;

    always_comb begin
        case(PCSrc)
            1'b0: PCNext = PCPlus4;
            1'b1: PCNext = PCTarget;
            default: PCNext = 5'b0;
        endcase
    end

    assign PCPlus4 = PC + 3'b100; // Double check whether this is valid way of adding PC + 4

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

    assign NOP = 32'b0      // Double check whether this is actually the canonical NOP

    // If Initializing Instr_Cache: Instr = NOP
    always_comb begin
        case(ChipEnable)
            1'b0: Instr = NOP;
            1'b1: Instr = InstrOut;
            default: Instr = 32'b0;
        endcase
    end

    // Register File 
    reg_file Reg_File(
        .clk(clk),
        .reset(reset),
        .write_enable(RegWrite),
        .A1(Instr[19:15]),
        .A2(Instr[24:20]),
        .A3(Instr[11:7]),
        .WD(Result),
        .RD1(SrcA),
        .RD2(WriteData)
    );

    // Immediate Extension
    always_comb begin
        case(ImmSrc)
            2'b00: ImmExt = {{20{Instr[31]}}, Instr[31:20]};                              // I type (12 bit signed)
            2'b01: ImmExt = {{20{Instr[31]}}, Instr[31:25], Instr[11:7]};                 // S type (12 bit signed)
            2'b10: ImmExt = {{20{Instr[31]}}, Instr[7], Instr[31:25], Instr[11:8], 1'b0}; // B type (13 bit signed)
            2'b11: ImmExt = {{12{Instr[31]}}, Instr[19:12], Instr[20, Instr[30:21], 1'b0};// J type (21 bit signed)
            default: ImmExt = 32'b0;
        endcase
    end

    // Mux for SrcB
    always_comb begin
        case(ALUSrc)
            1'b0: SrcB = WriteData;
            1'b1: SrcB = ImmExt;
            default: SrcB = 32'b0;
        endcase
    end

    // Define ALU Logic
    always_comb begin
        case(ALUControl)
            2'b00:
            2'b01:
            2'b10:
            default:
        endcase
    end

    data_mem Data_Memory(
        .clk(clk),
        .reset(reset),
        .write_enable(MemWrite),
        .A(ALUResult),
        .WD(WriteData),
        .RD(ReadData)
    );

    // Result Comb Logic
    always_comb begin
        case(ResultSrc)
            2'b00: Result = ALUResult;
            2'b01: Result = ReadData;
            2'b10: Result = ImmExt;
            default: Result = 32'b0;
        endcase
    end
    
endmodule