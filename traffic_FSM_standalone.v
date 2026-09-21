module traffic_FSM(
input clk,
input rst,
input [7:0] v0,v1,v2,v3,
output reg [3:0] green,
output reg [3:0] yellow, red,
output reg [15:0] timer
);

parameter YELLOW_TIME = 2;
parameter BASE = 5;
parameter FACTOR = 2;
parameter THRESHOLD = 30;

reg [1:0] state;
reg [1:0] next_state;


function [15:0] calc_time;
input [7:0] v;
begin
calc_time = BASE + FACTOR*v + YELLOW_TIME;
end
endfunction


function [1:0] max_lane_thresh;
input [7:0] a,b,c,d;
begin
if(a>=THRESHOLD && a>b && a>c && a>d)
max_lane_thresh = 2'd0;
else if(b>=THRESHOLD && b>c && b>d && b>a)
max_lane_thresh = 2'd1;
else if(c>=THRESHOLD && c>a && c>b && c>d)
max_lane_thresh = 2'd2;
else if(d>=THRESHOLD && d>a && d>b && d>c)
max_lane_thresh = 2'd3;
else
max_lane_thresh = 2'bxx;
end
endfunction


function [1:0] max_lane_veh;
input [7:0] a,b,c,d;
begin
if (a>=b && a>=c && a>=d)
max_lane_veh = 2'd0;
else if (b>=a && b>=c && b>=d)
max_lane_veh = 2'd1;
else if (c>=a && c>=b && c>=d)
max_lane_veh = 2'd2;
else
max_lane_veh = 2'd3;
end
endfunction

always @(posedge clk) begin
if(rst) begin
state <= max_lane_veh(v0,v1,v2,v3);
      
case(state)
2'd0: timer <= calc_time(v0);
2'd1: timer <= calc_time(v1);
2'd2: timer <= calc_time(v2);
2'd3: timer <= calc_time(v3);
endcase
end else begin
if(timer == 0) begin

if(^max_lane_thresh(v0,v1,v2,v3) !== 1'bx)
next_state <= max_lane_thresh(v0,v1,v2,v3);
else
next_state <= state + 1; 

state <= next_state;
case(next_state)
2'd0: timer <= calc_time(v0);
2'd1: timer <= calc_time(v1);
2'd2: timer <= calc_time(v2);
2'd3: timer <= calc_time(v3);
endcase
end else begin
timer <= timer - 1;
end
end
end

always @(*) begin
green = 4'b0000;
yellow = 4'b0000;
red = 4'b1111;

if(timer > YELLOW_TIME)
green[state] = 1;
else
yellow[state] = 1;

red = ~(green | yellow);
end

endmodule


