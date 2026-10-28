
module amtgc_top #(
    // Junction A timing
    parameter integer MIN_GREEN_TIME_A = 8,
    parameter integer MAX_GREEN_TIME_A = 20,
    parameter integer DENSITY_STEP_A   = 2,
    parameter integer YELLOW_TIME_A    = 3,
    parameter integer RED_TIME_A       = 2,
    parameter integer PED_TIME_A       = 6,
    // Junction B timing 
    parameter integer MIN_GREEN_TIME_B = 6,
    parameter integer MAX_GREEN_TIME_B = 16,
    parameter integer DENSITY_STEP_B   = 2,
    parameter integer YELLOW_TIME_B    = 3,
    parameter integer RED_TIME_B       = 2,
    parameter integer PED_TIME_B       = 6,
    // Shared
    parameter integer COUNTER_WIDTH   = 16,
    parameter integer GREEN_WAVE_DELAY = 5   // cycles after A's NS_GREEN that B's NS_GREEN should begin
) (
    input  wire clk,
    input  wire rst,                  // synchronous, active-high, system-wide

    input  wire emergency_override,   // system-wide emergency input

    input  wire [2:0] traffic_density_a, // Task 4: live traffic reading, Junction A
    input  wire [2:0] traffic_density_b, // Task 4: live traffic reading, Junction B

    input  wire ped_request_a,        // pedestrian request/button, Junction A
    input  wire ped_request_b,        // pedestrian request/button, Junction B

    // Junction A traffic light outputs
    output wire ns_green_a, ns_yellow_a, ew_green_a, ew_yellow_a, all_red_a, ped_walk_a,
    // Junction B traffic light outputs
    output wire ns_green_b, ns_yellow_b, ew_green_b, ew_yellow_b, all_red_b, ped_walk_b,

    output wire [3:0] state_a,
    output wire [3:0] state_b,
    output wire       ped_grant_a_dbg,
    output wire       ped_grant_b_dbg,
    output wire [COUNTER_WIDTH-1:0] green_target_a_dbg, // Task 4: adaptive target in use, per junction
    output wire [COUNTER_WIDTH-1:0] green_target_b_dbg
);

    wire ped_req_a, ped_req_b;
    wire ped_grant_a, ped_grant_b;
    wire gw_hold_b;

    assign ped_grant_a_dbg = ped_grant_a;
    assign ped_grant_b_dbg = ped_grant_b;

  
    junction_controller #(
        .MIN_GREEN_TIME (MIN_GREEN_TIME_A),
        .MAX_GREEN_TIME (MAX_GREEN_TIME_A),
        .DENSITY_STEP   (DENSITY_STEP_A),
        .YELLOW_TIME    (YELLOW_TIME_A),
        .RED_TIME       (RED_TIME_A),
        .PED_TIME       (PED_TIME_A),
        .COUNTER_WIDTH  (COUNTER_WIDTH)
    ) u_junction_a (
        .clk                (clk),
        .rst                (rst),
        .emergency_override (emergency_override),
        .gw_hold            (1'b0),          // Junction A is never held
        .traffic_density    (traffic_density_a),
        .ped_request        (ped_request_a),
        .ped_grant          (ped_grant_a),
        .ped_req_out        (ped_req_a),
        .ns_green           (ns_green_a),
        .ns_yellow          (ns_yellow_a),
        .ew_green           (ew_green_a),
        .ew_yellow          (ew_yellow_a),
        .all_red            (all_red_a),
        .ped_walk           (ped_walk_a),
        .state              (state_a),
        .green_target_dbg   (green_target_a_dbg)
    );

      junction_controller #(
        .MIN_GREEN_TIME (MIN_GREEN_TIME_B),
        .MAX_GREEN_TIME (MAX_GREEN_TIME_B),
        .DENSITY_STEP   (DENSITY_STEP_B),
        .YELLOW_TIME    (YELLOW_TIME_B),
        .RED_TIME       (RED_TIME_B),
        .PED_TIME       (PED_TIME_B),
        .COUNTER_WIDTH  (COUNTER_WIDTH)
    ) u_junction_b (
        .clk                (clk),
        .rst                (rst),
        .emergency_override (emergency_override),
        .gw_hold            (gw_hold_b),
        .traffic_density    (traffic_density_b),
        .ped_request        (ped_request_b),
        .ped_grant          (ped_grant_b),
        .ped_req_out        (ped_req_b),
        .ns_green           (ns_green_b),
        .ns_yellow          (ns_yellow_b),
        .ew_green           (ew_green_b),
        .ew_yellow          (ew_yellow_b),
        .all_red            (all_red_b),
        .ped_walk           (ped_walk_b),
        .state              (state_b),
        .green_target_dbg   (green_target_b_dbg)
    );

      ped_arbiter u_ped_arbiter (
        .clk     (clk),
        .rst     (rst),
        .req_a   (ped_req_a),
        .req_b   (ped_req_b),
        .grant_a (ped_grant_a),
        .grant_b (ped_grant_b)
    );

 
    localparam integer GW_CNT_WIDTH = 16;

    reg                       a_ns_green_d;
    reg                       gw_counting;
    reg                       gw_hold_b_reg;
    reg [GW_CNT_WIDTH-1:0]    gw_counter;

    wire a_ns_green_rise = ns_green_a & ~a_ns_green_d;

    always @(posedge clk) begin
        if (rst) begin
            a_ns_green_d <= 1'b0;
        end else begin
            a_ns_green_d <= ns_green_a;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            gw_counter    <= {GW_CNT_WIDTH{1'b0}};
            gw_counting   <= 1'b0;
            gw_hold_b_reg <= 1'b1;   // hold B until the offset is satisfied
        end else if (emergency_override) begin
          
            gw_counter    <= {GW_CNT_WIDTH{1'b0}};
            gw_counting   <= 1'b0;
            gw_hold_b_reg <= 1'b1;
        end else begin
            if (a_ns_green_rise && gw_hold_b_reg && !gw_counting) begin
                gw_counting <= 1'b1;
                gw_counter  <= {GW_CNT_WIDTH{1'b0}};
            end else if (gw_counting) begin
                if ((gw_counter + 1'b1) >= GREEN_WAVE_DELAY[GW_CNT_WIDTH-1:0]) begin
                    gw_hold_b_reg <= 1'b0;   // release Junction B
                    gw_counting   <= 1'b0;
                end else begin
                    gw_counter <= gw_counter + 1'b1;
                end
            end
        end
    end

    assign gw_hold_b = gw_hold_b_reg;

endmodule
