module uart_rx #(
    parameter CLK_FREQ  = 50_000_000,
    parameter BAUD_RATE = 9600
)(
    input        clk,
    input        rst,
    input        rx,
    output reg [7:0] data,
    output reg       valid
);
    localparam CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;

    localparam S_IDLE  = 2'd0;
    localparam S_START = 2'd1;
    localparam S_DATA  = 2'd2;
    localparam S_STOP  = 2'd3;

    reg [1:0]  state;
    reg [12:0] clk_cnt;
    reg [2:0]  bit_idx;
    reg [7:0]  rx_shift;
    reg        rx_sync1, rx_sync2;

    always @(posedge clk) begin
        rx_sync1 <= rx;
        rx_sync2 <= rx_sync1;
    end

    always @(posedge clk) begin
        valid <= 0;
        if (rst) begin
            state   <= S_IDLE;
            clk_cnt <= 0;
            bit_idx <= 0;
        end else begin
            case (state)
                S_IDLE: begin
                    if (rx_sync2 == 0) begin
                        clk_cnt <= 0;
                        state   <= S_START;
                    end
                end
                S_START: begin
                    if (clk_cnt == (CLKS_PER_BIT/2)) begin
                        if (rx_sync2 == 0) begin
                            clk_cnt <= 0;
                            bit_idx <= 0;
                            state   <= S_DATA;
                        end else
                            state <= S_IDLE;
                    end else
                        clk_cnt <= clk_cnt + 1;
                end
                S_DATA: begin
                    if (clk_cnt == CLKS_PER_BIT) begin
                        clk_cnt           <= 0;
                        rx_shift[bit_idx] <= rx_sync2;
                        if (bit_idx == 7)
                            state <= S_STOP;
                        else
                            bit_idx <= bit_idx + 1;
                    end else
                        clk_cnt <= clk_cnt + 1;
                end
                S_STOP: begin
                    if (clk_cnt == CLKS_PER_BIT) begin
                        if (rx_sync2 == 1) begin
                            data  <= rx_shift;
                            valid <= 1;
                        end
                        state   <= S_IDLE;
                        clk_cnt <= 0;
                    end else
                        clk_cnt <= clk_cnt + 1;
                end
            endcase
        end
    end
endmodule