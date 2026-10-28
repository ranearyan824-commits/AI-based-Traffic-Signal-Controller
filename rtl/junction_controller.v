`timescale 1ns / 1ps

module junction_controller #(
    parameter MIN_GREEN_TIME = 32'd5,   // Minimum safety limit
    parameter MAX_GREEN_TIME = 32'd15,  // Maximum safety limit to prevent starvation
    parameter YELLOW_TIME    = 32'd3,
    parameter RED_TIME       = 32'd2,
    parameter PED_TIME       = 32'd5,
    parameter IS_MASTER      = 1,
    parameter COUNTER_WIDTH  = 32
)(
    input wire clk,
    input wire rst_n,
    input wire ped_req,
    input wire emergency_override,
    input wire sync_in,
    input wire [2:0] traffic_density, // New Input for Task 4
    output wire sync_out,
    output reg [2:0] light_NS,
    output reg [2:0] light_EW
);

    localparam COLOR_RED    = 3'b100;
    localparam COLOR_YELLOW = 3'b010;
    localparam COLOR_GREEN  = 3'b001;

    localparam S_NS_GREEN  = 3'd0,
               S_NS_YELLOW = 3'd1,
               S_ALL_RED_1 = 3'd2,
               S_EW_GREEN  = 3'd3,
               S_EW_YELLOW = 3'd4,
               S_ALL_RED_2 = 3'd5,
               S_PED       = 3'd6,
               S_EMERGENCY = 3'd7;

    reg [2:0] state, next_state;
    wire timer_done;
    reg [COUNTER_WIDTH-1:0] timer_target;
    reg ped_req_pending, clear_ped_req;
    
    // Adaptive Timing Logic
    reg [31:0] active_green_time;
    wire [31:0] calculated_green_time;
    
    // Formula: Min Time + (Density * 2). Clamped at MAX_GREEN_TIME
    assign calculated_green_time = ((MIN_GREEN_TIME + (traffic_density * 2)) > MAX_GREEN_TIME) ? 
                                   MAX_GREEN_TIME : (MIN_GREEN_TIME + (traffic_density * 2));

    assign sync_out = (IS_MASTER && state == S_NS_GREEN) ? 1'b1 : 1'b0;

    // Generic Timer (UNMODIFIED interface)
    generic_timer #(.COUNTER_WIDTH(COUNTER_WIDTH)) u_timer (
        .clk(clk), .rst_n(rst_n), .start(1'b1),
        .count_target(timer_target), .done(timer_done)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_ALL_RED_1;
            ped_req_pending <= 1'b0;
            active_green_time <= MIN_GREEN_TIME;
        end else if (emergency_override) begin
            state <= S_EMERGENCY;
        end else begin
            state <= next_state;
            
            if (ped_req) ped_req_pending <= 1'b1;
            else if (clear_ped_req) ped_req_pending <= 1'b0;
            
            // DESIGN DECISION: Sample density ONLY at the start of a new green phase
            if ((state == S_ALL_RED_2 && next_state == S_NS_GREEN) || 
                (state == S_ALL_RED_1 && next_state == S_EW_GREEN)) begin
                active_green_time <= calculated_green_time;
            end
        end
    end

    always @(*) begin
        next_state    = state;
        timer_target  = RED_TIME;
        light_NS      = COLOR_RED;
        light_EW      = COLOR_RED;
        clear_ped_req = 1'b0;

        case (state)
            S_NS_GREEN: begin
                light_NS = COLOR_GREEN; timer_target = active_green_time; // Using Adaptive Time
                if (timer_done) next_state = S_NS_YELLOW;
            end
            S_NS_YELLOW: begin
                light_NS = COLOR_YELLOW; timer_target = YELLOW_TIME;
                if (timer_done) next_state = S_ALL_RED_1;
            end
            S_ALL_RED_1: begin
                timer_target = RED_TIME;
                if (timer_done) begin
                    if (ped_req_pending) next_state = S_PED;
                    else next_state = S_EW_GREEN;
                end
            end
            S_EW_GREEN: begin
                light_EW = COLOR_GREEN; timer_target = active_green_time; // Using Adaptive Time
                if (timer_done) next_state = S_EW_YELLOW;
            end
            S_EW_YELLOW: begin
                light_EW = COLOR_YELLOW; timer_target = YELLOW_TIME;
                if (timer_done) next_state = S_ALL_RED_2;
            end
            S_ALL_RED_2: begin
                timer_target = RED_TIME;
                if (timer_done) begin
                    if (ped_req_pending) next_state = S_PED;
                    else if (!IS_MASTER && !sync_in) next_state = S_ALL_RED_2;
                    else next_state = S_NS_GREEN;
                end
            end
            S_PED: begin
                timer_target = PED_TIME; clear_ped_req = 1'b1;
                if (timer_done) next_state = S_NS_GREEN;
            end
            S_EMERGENCY: begin
                light_NS = COLOR_RED; light_EW = COLOR_RED; timer_target = RED_TIME;
                if (!emergency_override) next_state = S_ALL_RED_1; 
            end
            default: next_state = S_ALL_RED_1;
        endcase
    end
endmodule
