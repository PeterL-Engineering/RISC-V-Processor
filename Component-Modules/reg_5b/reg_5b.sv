module reg_5b(
    input   logic        clk,
    input   logic        reset,
    input   logic        enable,
    input   logic [4:0]  D,
    output  logic [4:0]  Q
);

    always_ff @(posedge clk, posedge reset) begin
        if (reset)
            Q <= 5'b0;
        else if (enable)
            Q <= D;
        else
            Q <= Q;
    end

endmodule