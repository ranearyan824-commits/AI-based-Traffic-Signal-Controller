`timescale 1ns / 1ps

module generic_timer #(
    parameter COUNTER_WIDTH = 32
)(
    input wire clk,
    input wire rst_n,
    input wire start,
    input wire [COUNTER_WIDTH-1:0] count_target,
    output wire done
);

    reg [COUNTER_WIDTH-1:0] count;

    // Sequential logic (Non-blocking <= assignments)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= {COUNTER_WIDTH{1'b0}};
        end else if (!start) begin
            count <= {COUNTER_WIDTH{1'b0}};
        end else begin
            // Handle Corner Case: count_target = 0
            if (count_target == {COUNTER_WIDTH{1'b0}}) begin
                count <= {COUNTER_WIDTH{1'b0}};
            end 
            // Auto-reset when target is reached
            else if (count == count_target - 1) begin
                count <= {COUNTER_WIDTH{1'b0}}; 
            end 
            else begin
                count <= count + 1'b1;
            end
        end
    end

    // Combinational logic (Blocking = assignment implicitly via assign)
    assign done = (start && (count_target == {COUNTER_WIDTH{1'b0}})) ? 1'b1 :
                  (start && (count == count_target - 1)) ? 1'b1 : 1'b0;

endmodule
