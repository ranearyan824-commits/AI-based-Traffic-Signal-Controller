`timescale 1ns / 1ps

module tb_junction_controller;
    reg clk;
    reg rst_n;
    reg ped_req;
    wire [2:0] light_NS;
    wire [2:0] light_EW;

    // Small parameter values for quick simulation
    junction_controller #(
        .GREEN_TIME(5), .YELLOW_TIME(2), .RED_TIME(2), .PED_TIME(4)
    ) uut (
        .clk(clk), .rst_n(rst_n), .ped_req(ped_req),
        .light_NS(light_NS), .light_EW(light_EW)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0; rst_n = 0; ped_req = 0;
        #15 rst_n = 1;
        
        // Let it run one normal cycle
        #100;
        
        // Corner Case: Send Pedestrian Request during NS Green/Yellow
        ped_req = 1;
        #10 ped_req = 0; 
        
        // Wait and observe if it goes to ALL_RED -> PED phase safely
        #100;

        $display("Junction Controller Simulation completed!");
        $stop;
    end
endmodule
