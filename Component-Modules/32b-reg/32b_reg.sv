module 32b_reg(
    input logic [31:0] D,
    input logic clk, reset, enable,
    output logic [31:0] Q
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