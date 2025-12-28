`timescale 1ns/1ps

module reg_32b_tb;
    // DUT signals
    logic        clk;
    logic        reset;
    logic        enable;
    logic [31:0] D;
    logic [31:0] Q;
    
    // Instantiate DUT (note: module name can't start with number)
    reg_32b dut (
        .clk    (clk),
        .reset  (reset),
        .enable (enable),
        .D      (D),
        .Q      (Q)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 100 MHz
    end
    
    // Main test
    initial begin
        // Initialize
        reset = 1;
        enable = 0;
        D = 0;
        #20;
        
        // Test 1: Reset release
        reset = 0;
        #10;
        
        // Test 2: Write with enable
        enable = 1;
        D = 32'h12345678;
        #10;
        
        // Test 3: Read (should see data)
        #5;
        $display("Q = 0x%h (expected: 0x12345678)", Q);
        
        // Test 4: Hold with enable=0
        enable = 0;
        D = 32'hDEADBEEF;
        #10;
        $display("Q = 0x%h (should still be 0x12345678)", Q);
        
        // Test 5: New write
        enable = 1;
        #10;
        $display("Q = 0x%h (expected: 0xDEADBEEF)", Q);
        
        // Test 6: Reset
        reset = 1;
        #10;
        $display("Q = 0x%h (should be 0 after reset)", Q);
        
        $finish;
    end
    
endmodule