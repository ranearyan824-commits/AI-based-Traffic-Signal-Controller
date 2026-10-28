`timescale 1ns / 1ps

module tb_generic_timer;
    reg clk;
    reg rst_n;
    reg start;
    reg [31:0] count_target;
    wire done;

    generic_timer #(.COUNTER_WIDTH(32)) uut (
        .clk(clk), .rst_n(rst_n), .start(start),
        .count_target(count_target), .done(done)
    );

    always #5 clk = ~clk; // 10ns clock period

    initial begin
        clk = 0; rst_n = 0; start = 0; count_target = 0;
        #15 rst_n = 1;
        
        // Test 1: Parameter Target = 5
        start = 1; count_target = 5;
        wait(done);
        #10;
        
        // Test 2: Parameter Target = 10
        count_target = 10;
        wait(done);
        #10;
        
        // Test 3: Corner Case Target = 0 (Should assert done immediately)
        count_target = 0;
        #20;
        
        $display("All Timer tests passed successfully!");
        $stop;
    end
endmodule
