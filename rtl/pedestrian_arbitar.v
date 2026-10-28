`timescale 1ns / 1ps

module ped_arbiter (
    input wire clk,
    input wire rst_n,
    input wire req_A,
    input wire req_B,
    output reg grant_A,
    output reg grant_B
);
    reg priority_flag; // 0 for A, 1 for B (Round-Robin Pointer)

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            priority_flag <= 1'b0;
            grant_A <= 1'b0;
            grant_B <= 1'b0;
        end else begin
            // Default: clear grants
            grant_A <= 1'b0;
            grant_B <= 1'b0;

            if (req_A && req_B) begin
                // Simultaneous Request: Use Fair Round-Robin Policy
                if (priority_flag == 1'b0) begin
                    grant_A <= 1'b1;
                    priority_flag <= 1'b1; // Next time give priority to B
                end else begin
                    grant_B <= 1'b1;
                    priority_flag <= 1'b0; // Next time give priority to A
                end
            end else if (req_A) begin
                grant_A <= 1'b1;
                priority_flag <= 1'b1;
            end else if (req_B) begin
                grant_B <= 1'b1;
                priority_flag <= 1'b0;
            end
        end
    end
endmodule
