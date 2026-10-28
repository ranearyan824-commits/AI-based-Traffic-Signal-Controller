`timescale 1ns / 1ps

module amtgc_top (
    input wire clk,
    input wire rst_n,
    input wire emergency_override,
    input wire ped_req_A,
    input wire ped_req_B,
    input wire [2:0] traffic_density_A, // Task 4: New Input
    input wire [2:0] traffic_density_B, // Task 4: New Input
    output wire [2:0] light_NS_A,
    output wire [2:0] light_EW_A,
    output wire [2:0] light_NS_B,
    output wire [2:0] light_EW_B
);

    wire grant_A, grant_B;
    wire sync_out_A;
    reg [4:0] green_wave_delay;
    reg sync_in_B;

    ped_arbiter u_arbiter (
        .clk(clk), .rst_n(rst_n), .req_A(ped_req_A), .req_B(ped_req_B),
        .grant_A(grant_A), .grant_B(grant_B)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            green_wave_delay <= 0;
            sync_in_B <= 0;
        end else begin
            if (sync_out_A) green_wave_delay <= 5; 
            
            if (green_wave_delay > 0) begin
                green_wave_delay <= green_wave_delay - 1;
                sync_in_B <= (green_wave_delay == 1) ? 1'b1 : 1'b0;
            end else begin
                sync_in_B <= 1'b0;
            end
        end
    end

    junction_controller #(
        .MIN_GREEN_TIME(5), .MAX_GREEN_TIME(15), .YELLOW_TIME(3), .RED_TIME(2), .PED_TIME(5), .IS_MASTER(1)
    ) u_junction_A (
        .clk(clk), .rst_n(rst_n), .ped_req(grant_A), .emergency_override(emergency_override),
        .sync_in(1'b0), .sync_out(sync_out_A), .traffic_density(traffic_density_A),
        .light_NS(light_NS_A), .light_EW(light_EW_A)
    );

    junction_controller #(
        .MIN_GREEN_TIME(5), .MAX_GREEN_TIME(15), .YELLOW_TIME(3), .RED_TIME(2), .PED_TIME(5), .IS_MASTER(0)
    ) u_junction_B (
        .clk(clk), .rst_n(rst_n), .ped_req(grant_B), .emergency_override(emergency_override),
        .sync_in(sync_in_B), .sync_out(), .traffic_density(traffic_density_B),
        .light_NS(light_NS_B), .light_EW(light_EW_B)
    );

endmodule
