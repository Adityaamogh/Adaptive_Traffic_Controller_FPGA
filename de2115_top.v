module de2115_top(
    input        CLOCK_50,
    input  [3:0] KEY,
    input        UART_RXD,
    output [17:0] LEDR,
    output [8:0]  LEDG,
    output [6:0]  HEX0, HEX1, HEX2, HEX3, HEX4, HEX5
);
    reg [25:0] clk_div;
    reg        clk_1hz;
    always @(posedge CLOCK_50) begin
        if (clk_div == 26'd49_999_999) begin
            clk_div <= 0;
            clk_1hz <= ~clk_1hz;
        end else begin
            clk_div <= clk_div + 1;
        end
    end

    wire rst = ~KEY[0];

    wire [7:0] rx_data;
    wire       rx_valid;
    uart_rx #(
        .CLK_FREQ(50_000_000),
        .BAUD_RATE(9600)
    ) urx (
        .clk  (CLOCK_50),
        .rst  (rst),
        .rx   (UART_RXD),
        .data (rx_data),
        .valid(rx_valid)
    );

    wire [7:0] v0, v1, v2, v3;
    wire       data_ready;
    packet_parser pp (
        .clk       (CLOCK_50),
        .rst       (rst),
        .rx_valid  (rx_valid),
        .rx_data   (rx_data),
        .v0        (v0),
        .v1        (v1),
        .v2        (v2),
        .v3        (v3),
        .data_ready(data_ready)
    );

    wire [3:0]  green_w, yellow_w, red_w;
    wire [15:0] timer_w;
    wire [1:0]  state_w;
    traffic_FSM fsm (
        .clk      (clk_1hz),
        .rst      (rst),
        .v0       (v0),
        .v1       (v1),
        .v2       (v2),
        .v3       (v3),
        .green    (green_w),
        .yellow   (yellow_w),
        .red      (red_w),
        .timer    (timer_w),
        .state_out(state_w)
    );

    assign LEDR[3:0]  = red_w;
    assign LEDR[17:4] = 14'b0;
    assign LEDG[3:0]  = green_w;
    assign LEDG[7:4]  = yellow_w;
    assign LEDG[8]    = 1'b0;

    seg7 s0(.in(timer_w % 10),          .out(HEX0));
    seg7 s1(.in((timer_w / 10)  % 10),  .out(HEX1));
    seg7 s2(.in((timer_w / 100) % 10),  .out(HEX2));
    seg7 s3(.in((timer_w / 1000)% 10),  .out(HEX3));
    seg7 s4(.in({2'b00, state_w}),      .out(HEX4));
    assign HEX5 = 7'b1111111;

endmodule

module seg7(
    input      [3:0] in,
    output reg [6:0] out
);
    always @(*) begin
        case (in)
            4'd0: out = 7'b100_0000;
            4'd1: out = 7'b111_1001;
            4'd2: out = 7'b010_0100;
            4'd3: out = 7'b011_0000;
            4'd4: out = 7'b001_1001;
            4'd5: out = 7'b001_0010;
            4'd6: out = 7'b000_0010;
            4'd7: out = 7'b111_1000;
            4'd8: out = 7'b000_0000;
            4'd9: out = 7'b001_0000;
            default: out = 7'b111_1111;
        endcase
    end
endmodule