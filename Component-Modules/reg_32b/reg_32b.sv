module reg_32b(
    input   logic        clk,
    input   logic        reset,
    input   logic        enable,
    input   logic [31:0] D,
    output  logic [31:0] Q
);

always_ff @(posedge clk, posedge reset) begin
    if (reset)
        Q <= 32'b0;
    else if (enable)
        Q <= D;
    else
        Q <= Q;
end

endmodule