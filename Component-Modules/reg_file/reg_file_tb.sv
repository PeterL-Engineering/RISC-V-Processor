`timescale 1ns/1ps

module reg_file_tb;
    // DUT Signals
    logic           clk;
    logic           reset;  
    logic           write_enable;
    logic  [4:0]    A1;     // Read address 1 (rs1)
    logic  [4:0]    A2;     // Read address 2 (rs2) 
    logic  [4:0]    A3;     // Write address (rd)
    logic  [31:0]   WD;     // Write data
    
    logic  [31:0]   RD1;    // Read data 1
    logic  [31:0]   RD2;    // Read data 2

    // Testbench variables
    logic [31:0] memory_model [0:31];  // Reference model
    int test_count = 0;
    int error_count = 0;

    // Instantiate DUT
    reg_file dut (
        .clk            (clk),
        .reset          (reset),
        .write_enable   (write_enable),
        .A1             (A1),
        .A2             (A2),
        .A3             (A3),
        .WD             (WD),
        .RD1            (RD1),
        .RD2            (RD2)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100 MHz clock
    end

    // Wait for specified number of clock cycles
    task automatic wait_cycles(input int cycles);
        repeat (cycles) @(posedge clk);
    endtask

    // Initialize signals
    task automatic init_signals();
        reset = 1;
        write_enable = 0;
        A1 = 5'b0;
        A2 = 5'b0;
        A3 = 5'b0;
        WD = 32'b0;
        
        // Initialize reference model (x0 is always 0)
        for (int i = 0; i < 32; i++) begin
            memory_model[i] = 32'h0;
        end
        $display("[%0t] Initialization complete", $time);
    endtask

    // Reset task
    task automatic apply_reset();
        @(negedge clk);
        reset = 1;
        @(posedge clk);
        #1 reset = 0;
        $display("[%0t] Reset applied", $time);
    endtask

    // Write to registers using normal interface
    task automatic write_reg(
        input logic [4:0] addr_i,
        input logic [31:0] data_i
    );
        @(negedge clk);  // Setup before clock edge
        write_enable = 1;
        A3 = addr_i;    // Fixed: Use A3 for write address, not A1
        WD = data_i;

        @(posedge clk); // Write happens here
        #1;     // Small delay for propagation
        
        write_enable = 0;
        A3 = 5'b0;
        WD = 32'b0;

        // Update reference model (except for x0)
        if (addr_i != 5'b0) begin
            memory_model[addr_i] = data_i;
        end
        
        $display("[%0t] WRITE: Addr=%0d, Data=0x%08h", $time, addr_i, data_i);
        wait_cycles(1);
    endtask

    // Read and verify single port (RD1)
    task automatic read_and_verify_rd1(
        input logic [4:0] addr_i,
        input logic [31:0] expected_data_i = 'x
    );
        logic [31:0] ref_data;
        logic [31:0] expected_data;

        @(negedge clk);  // Setup before clock edge
        write_enable = 0;
        A1 = addr_i;
        A2 = 5'b0;  // Don't interfere with RD2

        #1; // Small delay for combinational logic

        // Get expected data from reference model
        ref_data = (addr_i == 5'b0) ? 32'b0 : memory_model[addr_i];

        // Override with explicit expected value if provided
        if (expected_data_i !== 'x) begin
            expected_data = expected_data_i;
        end else begin
            expected_data = ref_data;
        end
        
        // Verify the data (RD1 should be available immediately)
        if (RD1 === expected_data) begin
            $display("[%0t] READ RD1: Addr=%0d, Data=0x%08h ✓", 
                     $time, addr_i, RD1);
        end else begin
            $error("[%0t] READ RD1: Addr=%0d, Expected=0x%08h, Got=0x%08h ✗", 
                   $time, addr_i, expected_data, RD1);
            error_count++;
        end
        
        @(posedge clk);  // Align to clock edge
        A1 = 5'b0;
        
        test_count++;
        wait_cycles(1);
    endtask

    // Read and verify both ports
    task automatic read_and_verify_both(
        input logic [4:0] addr1_i,
        input logic [4:0] addr2_i,
        input logic [31:0] expected_data1_i = 'x,
        input logic [31:0] expected_data2_i = 'x
    );
        logic [31:0] expected_data1;
        logic [31:0] expected_data2;

        @(negedge clk);  // Setup before clock edge
        write_enable = 0;
        A1 = addr1_i;
        A2 = addr2_i;

        #1; // Small delay for combinational logic

        // Get expected data from reference model
        expected_data1 = (expected_data1_i !== 'x) ? expected_data1_i : 
                        ((addr1_i == 5'b0) ? 32'b0 : memory_model[addr1_i]);
        expected_data2 = (expected_data2_i !== 'x) ? expected_data2_i : 
                        ((addr2_i == 5'b0) ? 32'b0 : memory_model[addr2_i]);
        
        // Verify both ports
        if (RD1 === expected_data1 && RD2 === expected_data2) begin
            $display("[%0t] READ BOTH: Addr1=%0d(0x%08h), Addr2=%0d(0x%08h) ✓", 
                     $time, addr1_i, RD1, addr2_i, RD2);
        end else begin
            $error("[%0t] READ BOTH: Addr1=%0d, Expected1=0x%08h, Got1=0x%08h", 
                   $time, addr1_i, expected_data1, RD1);
            $error("[%0t]           Addr2=%0d, Expected2=0x%08h, Got2=0x%08h ✗", 
                   $time, addr2_i, expected_data2, RD2);
            error_count++;
        end
        
        @(posedge clk);  // Align to clock edge
        A1 = 5'b0;
        A2 = 5'b0;
        
        test_count += 2;
        wait_cycles(1);
    endtask

    // Test x0 behavior
    task automatic test_x0();
        $display("\n[%0t] === Testing x0 behavior ===", $time);
        
        // Try to write to x0 (should be ignored)
        write_reg(5'b00000, 32'hDEADBEEF);
        
        // Read from x0 (should always be 0)
        read_and_verify_rd1(5'b00000, 32'h0);
        
        // Read from x0 while writing elsewhere
        @(negedge clk);
        A1 = 5'b00000;  // Read x0
        A3 = 5'b00001;  // Write to x1
        WD = 32'h12345678;
        write_enable = 1;
        @(posedge clk);
        #1;
        if (RD1 !== 32'b0) begin
            $error("x0 not zero during write cycle: Got 0x%08h", RD1);
            error_count++;
        end
        write_enable = 0;
        
        $display("[%0t] === x0 test complete ===", $time);
    endtask

    // Main test sequence
    initial begin
        $display("\n[%0t] ========================================", $time);
        $display("[%0t] Starting Register File Testbench", $time);
        $display("[%0t] ========================================", $time);
        
        // Initialize
        init_signals();
        wait_cycles(2);
        
        // Apply reset
        apply_reset();
        
        // Test 1: Verify reset cleared all registers
        $display("\n[%0t] === Test 1: Reset verification ===", $time);
        for (int i = 1; i < 32; i++) begin
            read_and_verify_rd1(i, 32'h0);
        end
        
        // Test 2: Write and read random values
        $display("\n[%0t] === Test 2: Write/Read operations ===", $time);
        write_reg(5'b00001, 32'h11111111);
        write_reg(5'b00010, 32'h22222222);
        write_reg(5'b00100, 32'h44444444);
        write_reg(5'b01000, 32'h88888888);
        write_reg(5'b10000, 32'hFFFFFFFF);
        
        read_and_verify_rd1(5'b00001);
        read_and_verify_rd1(5'b00010);
        read_and_verify_rd1(5'b00100);
        read_and_verify_rd1(5'b01000);
        read_and_verify_rd1(5'b10000);
        
        // Test 3: Simultaneous read from both ports
        $display("\n[%0t] === Test 3: Simultaneous reads ===", $time);
        read_and_verify_both(5'b00001, 5'b00010);  // x1 and x2
        read_and_verify_both(5'b00100, 5'b01000);  // x4 and x8
        read_and_verify_both(5'b10000, 5'b00001);  // x16 and x1
        
        // Test 4: Read while writing (different registers)
        $display("\n[%0t] === Test 4: Read during write ===", $time);
        @(negedge clk);
        A1 = 5'b00001;  // Read x1
        A2 = 5'b00010;  // Read x2
        A3 = 5'b00111;  // Write to x7
        WD = 32'h77777777;
        write_enable = 1;
        @(posedge clk);
        #1;
        if (RD1 !== 32'h11111111) begin
            $error("Read during write failed: Expected 0x11111111, got 0x%08h", RD1);
            error_count++;
        end
        if (RD2 !== 32'h22222222) begin
            $error("Read during write failed: Expected 0x22222222, got 0x%08h", RD2);
            error_count++;
        end
        write_enable = 0;
        @(negedge clk);
        
        // Test 5: Test x0 special case
        test_x0();
        
        // Test 6: Overwrite test
        $display("\n[%0t] === Test 6: Overwrite test ===", $time);
        write_reg(5'b00001, 32'hAAAAAAAA);  // Overwrite x1
        read_and_verify_rd1(5'b00001);
        
        // Final summary
        $display("\n[%0t] ========================================", $time);
        $display("[%0t] Test Summary:", $time);
        $display("[%0t]   Total tests: %0d", $time, test_count);
        $display("[%0t]   Errors:      %0d", $time, error_count);
        if (error_count == 0) begin
            $display("[%0t]   ALL TESTS PASSED! ✓", $time);
        end else begin
            $display("[%0t]   TESTS FAILED! ✗", $time);
        end
        $display("[%0t] ========================================", $time);
        
        #100 $finish;
    end

    // Timeout
    initial begin
        #1000000;  // 1ms timeout
        $display("[%0t] ERROR: Testbench timeout!", $time);
        $finish;
    end

endmodule