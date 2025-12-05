`timescale 1ns/1ps

module sync_sram_tb;

    // Testbench parameters
    localparam CLK_PERIOD = 10;  // 100 MHz clock
    localparam TEST_DEPTH = 32;  // Test all 32 addresses
    
    // DUT signals
    logic           clk;
    logic           chip_enable;
    logic           write_enable;
    logic [4:0]     addr;
    logic [31:0]    data_in;
    logic [31:0]    data_out;
    
    logic           init_en;
    logic [4:0]     init_addr;
    logic [31:0]    init_data;
    logic           init_we;
    
    // Testbench variables
    logic [31:0] memory_model [0:31];  // Reference model
    int test_count = 0;
    int error_count = 0;
    
    // Instantiate DUT
    sync_sram dut (
        .clk          (clk),
        .chip_enable  (chip_enable),
        .write_enable (write_enable),
        .addr         (addr),
        .data_in      (data_in),
        .data_out     (data_out),
        .init_en      (init_en),
        .init_addr    (init_addr),
        .init_data    (init_data),
        .init_we      (init_we)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Initialize signals
    task automatic init_signals;
        chip_enable = 0;
        write_enable = 0;
        addr = 0;
        data_in = 0;
        init_en = 0;
        init_addr = 0;
        init_data = 0;
        init_we = 0;
        
        // Initialize reference model
        for (int i = 0; i < 32; i++) begin
            memory_model[i] = 32'hXXXXXXXX;  // Unknown state
        end
    endtask
    
    // Wait for N clock cycles
    task automatic wait_cycles(input int cycles);
        repeat (cycles) @(posedge clk);
    endtask
    
    // Initialize memory using init interface
    task automatic init_memory(
        input logic [4:0] init_addr_i,
        input logic [31:0] init_data_i
    );
        @(negedge clk);  // Setup before clock edge
        init_en = 1;
        init_we = 1;
        init_addr = init_addr_i;
        init_data = init_data_i;
        
        @(posedge clk);  // Write happens here
        #1;  // Small delay for propagation
        
        init_en = 0;
        init_we = 0;
        
        // Update reference model
        memory_model[init_addr_i] = init_data_i;
        
        $display("[%0t] INIT: Addr=%0d, Data=0x%08h", $time, init_addr_i, init_data_i);
        wait_cycles(1);
    endtask
    
    // Write to memory using normal interface
    task automatic write_memory(
        input logic [4:0] addr_i,
        input logic [31:0] data_i
    );
        @(negedge clk);  // Setup before clock edge
        chip_enable = 1;
        write_enable = 1;
        addr = addr_i;
        data_in = data_i;
        
        @(posedge clk);  // Write happens here
        #1;  // Small delay for propagation
        
        chip_enable = 0;
        write_enable = 0;
        
        // Update reference model
        memory_model[addr_i] = data_i;
        
        $display("[%0t] WRITE: Addr=%0d, Data=0x%08h", $time, addr_i, data_i);
        wait_cycles(1);
    endtask
    
    // Read from memory and verify (COMBINATIONAL - immediate)
    task automatic read_and_verify(
        input logic [4:0] addr_i,
        input logic [31:0] expected_data_i = 'x
    );
        logic [31:0] ref_data;
        
        @(negedge clk);  // Setup before clock edge
        chip_enable = 1;
        write_enable = 0;
        addr = addr_i;
        
        #1;  // Small delay for combinational logic
        
        // Get expected data from reference model
        ref_data = memory_model[addr_i];
        
        // Override with explicit expected value if provided
        if (expected_data_i !== 'x) begin
            ref_data = expected_data_i;
        end
        
        // Verify the data (data_out should be available immediately)
        if (data_out === ref_data) begin
            $display("[%0t] READ:  Addr=%0d, Data=0x%08h ✓", $time, addr_i, data_out);
        end else begin
            $error("[%0t] READ:  Addr=%0d, Expected=0x%08h, Got=0x%08h ✗", 
                   $time, addr_i, ref_data, data_out);
            error_count++;
        end
        
        @(posedge clk);  // Align to clock edge
        chip_enable = 0;
        
        test_count++;
        wait_cycles(1);
    endtask
    
    // Test 1: Basic initialization test
    task automatic test_initialization;
        $display("\n=== Test 1: Initialization Interface Test ===");
        
        // Initialize some locations
        init_memory(5'd0,  32'hDEADBEEF);
        init_memory(5'd1,  32'hCAFEBABE);
        init_memory(5'd31, 32'h12345678);
        
        // Verify initialization (check immediately after write)
        read_and_verify(5'd0);   // Should be 0xDEADBEEF
        read_and_verify(5'd1);   // Should be 0xCAFEBABE  
        read_and_verify(5'd31);  // Should be 0x12345678
        
        // Check uninitialized location (should be X)
        read_and_verify(5'd10);
    endtask
    
    // Test 2: Normal read/write test
    task automatic test_read_write;
        $display("\n=== Test 2: Normal Read/Write Test ===");
        
        // Write using normal interface
        write_memory(5'd2,  32'hA5A5A5A5);
        write_memory(5'd3,  32'h5A5A5A5A);
        write_memory(5'd4,  32'hFFFFFFFF);
        
        // Read back (immediate verification)
        read_and_verify(5'd2);  // Should be 0xA5A5A5A5
        read_and_verify(5'd3);  // Should be 0x5A5A5A5A
        read_and_verify(5'd4);  // Should be 0xFFFFFFFF
    endtask
    
    // Test 3: Priority test (init vs normal)
    task automatic test_priority;
        $display("\n=== Test 3: Priority Test (Init > Normal) ===");
        
        // Write to address 5 using normal interface
        write_memory(5'd5, 32'h11111111);
        read_and_verify(5'd5);  // Should be 0x11111111
        
        // Simultaneously try normal write and init write (init should win)
        @(negedge clk);
        chip_enable = 1;
        write_enable = 1;
        addr = 5'd5;
        data_in = 32'h22222222;  // This should be ignored
        
        init_en = 1;
        init_we = 1;
        init_addr = 5'd5;
        init_data = 32'h33333333;  // This should be written
        
        @(posedge clk);
        #1;
        chip_enable = 0;
        write_enable = 0;
        init_en = 0;
        init_we = 0;
        
        // Update reference model for init write
        memory_model[5'd5] = 32'h33333333;
        
        // Verify init write took priority
        read_and_verify(5'd5);  // Should be 0x33333333
    endtask
    
    // Test 4: Immediate read-after-write test
    task automatic test_immediate_read;
        $display("\n=== Test 4: Immediate Read-After-Write ===");
        
        // Write and read same address in same cycle
        @(negedge clk);
        chip_enable = 1;
        write_enable = 1;
        addr = 5'd9;
        data_in = 32'h99999999;
        
        @(posedge clk);
        #1;
        
        // Immediately read same address (combinational output should show new data)
        write_enable = 0;
        #1;
        
        if (data_out === 32'h99999999) begin
            $display("[%0t] IMMEDIATE READ: Addr=9, Data=0x%08h ✓", $time, data_out);
        end else begin
            $error("[%0t] IMMEDIATE READ: Expected 0x99999999, Got 0x%08h ✗", $time, data_out);
            error_count++;
        end
        
        chip_enable = 0;
        wait_cycles(1);
    endtask
    
    // Test 5: Full memory test
    task automatic test_full_memory;
        $display("\n=== Test 5: Full Memory Test ===");
        
        // Write pattern to all addresses
        for (int i = 0; i < TEST_DEPTH; i++) begin
            write_memory(i[4:0], {16'hFACE, i[15:0]});
        end
        
        // Read back all addresses (immediate verification)
        for (int i = 0; i < TEST_DEPTH; i++) begin
            read_and_verify(i[4:0], {16'hFACE, i[15:0]});
        end
    endtask
    
    // Test 6: Concurrent operations test
    task automatic test_concurrent;
        $display("\n=== Test 6: Concurrent Operations Test ===");
        
        // Initialize some data
        init_memory(5'd7, 32'h11111111);
        init_memory(5'd8, 32'h22222222);
        
        // Test changing address while reading
        @(negedge clk);
        chip_enable = 1;
        write_enable = 0;
        addr = 5'd7;  // Read address 7
        
        #5;  // Mid-cycle, change address
        addr = 5'd8;
        
        #5;  // Check data_out immediately reflects new address
        if (data_out === 32'h22222222) begin
            $display("[%0t] CONCURRENT: Addr=8, Data=0x%08h ✓", $time, data_out);
        end else begin
            $error("[%0t] CONCURRENT: Expected 0x22222222, Got 0x%08h ✗", $time, data_out);
            error_count++;
        end
        
        @(posedge clk);
        chip_enable = 0;
        wait_cycles(1);
    endtask
    
    // Main test sequence
    initial begin
        $display("\n=========================================");
        $display("     sync_sram Testbench Started");
        $display("=========================================");
        
        // Initialize
        init_signals();
        wait_cycles(2);
        
        // Run tests
        test_initialization();
        wait_cycles(2);
        
        test_read_write();
        wait_cycles(2);
        
        test_priority();
        wait_cycles(2);
        
        test_immediate_read();
        wait_cycles(2);
        
        test_full_memory();
        wait_cycles(2);
        
        test_concurrent();
        wait_cycles(2);
        
        // Summary
        $display("\n=========================================");
        $display("     Test Summary");
        $display("=========================================");
        $display("Total tests run: %0d", test_count);
        $display("Errors: %0d", error_count);
        
        if (error_count == 0) begin
            $display("\n✓ All tests PASSED!");
        end else begin
            $display("\n✗ %0d test(s) FAILED!", error_count);
        end
        
        $display("\nSimulation completed at time %0t ns", $time);
        $finish;
    end
    
    // Monitor for debugging
    initial begin
        forever @(negedge clk) begin
            if (chip_enable) begin
                $display("[%0t] MONITOR: addr=%0d, we=%b, data_in=0x%08h, data_out=0x%08h",
                        $time, addr, write_enable, data_in, data_out);
            end
        end
    end
    
    // Waveform dumping (for debugging)
    initial begin
        $dumpfile("sync_sram_tb.vcd");
        $dumpvars(0, sync_sram_tb);
    end
    
    // Timeout check
    initial begin
        #1000000;  // 1ms timeout
        $display("\n⏰ Simulation timeout!");
        $finish;
    end

endmodule