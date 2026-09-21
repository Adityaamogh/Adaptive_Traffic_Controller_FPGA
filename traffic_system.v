module traffic_FSM(
    input        clk,
    input        rst,
    input  [7:0] v0,v1,v2,v3,
    output reg [3:0]  green,
    output reg [3:0]  yellow,
    output reg [3:0]  red,
    output reg [15:0] timer,
    output reg [1:0]  state_out
);
    parameter YELLOW_TIME = 2;
    parameter BASE        = 5;
    parameter FACTOR      = 2;

    reg [1:0] state;

    wire [7:0] dyn_thresh;
    assign dyn_thresh = ((v0 + v1 + v2 + v3) >> 3) + 7;

    function [15:0] calc_time;
        input [7:0] v;
        calc_time = BASE + (FACTOR * v) + YELLOW_TIME;
    endfunction

    function [1:0] max_lane_veh;
        input [7:0] a, b, c, d;
        if      (a >= b && a >= c && a >= d) max_lane_veh = 2'd0;
        else if (b >= a && b >= c && b >= d) max_lane_veh = 2'd1;
        else if (c >= a && c >= b && c >= d) max_lane_veh = 2'd2;
        else                                 max_lane_veh = 2'd3;
    endfunction

    always @(posedge clk) begin
        if (rst) begin
            state <= 2'd0;
            timer <= calc_time(v0);
        end else begin
            if (timer == 0) begin
                begin : next_blk
                    reg [1:0]  nxt;
                    reg [1:0]  thresh_lane;
                    reg        thresh_hit;

                    thresh_hit  = 1'b0;
                    thresh_lane = 2'd0;

                    if      (v0 >= dyn_thresh && v0 > v1 && v0 > v2 && v0 > v3) begin
                        thresh_hit = 1'b1; thresh_lane = 2'd0;
                    end
                    else if (v1 >= dyn_thresh && v1 > v0 && v1 > v2 && v1 > v3) begin
                        thresh_hit = 1'b1; thresh_lane = 2'd1;
                    end
                    else if (v2 >= dyn_thresh && v2 > v0 && v2 > v1 && v2 > v3) begin
                        thresh_hit = 1'b1; thresh_lane = 2'd2;
                    end
                    else if (v3 >= dyn_thresh && v3 > v0 && v3 > v1 && v3 > v2) begin
                        thresh_hit = 1'b1; thresh_lane = 2'd3;
                    end

                    if (thresh_hit)
                        nxt = thresh_lane;
                    else
                        nxt = max_lane_veh(v0, v1, v2, v3);

                    state <= nxt;

                    case (nxt)
                        2'd0: timer <= calc_time(v0);
                        2'd1: timer <= calc_time(v1);
                        2'd2: timer <= calc_time(v2);
                        2'd3: timer <= calc_time(v3);
                    endcase
                end
            end else begin
                timer <= timer - 1;
            end
        end
    end

    always @(*) state_out = state;

    always @(*) begin
        green  = 4'b0000;
        yellow = 4'b0000;
        if (timer > YELLOW_TIME)
            green[state]  = 1'b1;
        else
            yellow[state] = 1'b1;
        red = ~(green | yellow);
    end

endmodule