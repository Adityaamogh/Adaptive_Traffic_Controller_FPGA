// ============================================================
// packet_parser.v
// Reads 6-byte packets: [0xAA][v0][v1][v2][v3][chk]
// ============================================================
module packet_parser(
    input        clk,
    input        rst,
    // from uart_rx
    input        rx_valid,
    input  [7:0] rx_data,
    // to FSM
    output reg [7:0] v0, v1, v2, v3,
    output reg       data_ready   // pulses 1 cycle when new counts loaded
);
    reg [2:0] byte_idx;
    reg [7:0] rx_buf[0:4];   // FIXED: renamed from buf to rx_buf

    always @(posedge clk) begin
        data_ready <= 0;
        if (rst) begin
            byte_idx <= 0;
            v0 <= 0; v1 <= 0; v2 <= 0; v3 <= 0;
        end else if (rx_valid) begin
            if (byte_idx == 0) begin
                // Wait for start byte
                if (rx_data == 8'hAA)
                    byte_idx <= 1;
            end else begin
                rx_buf[byte_idx - 1] <= rx_data;   // FIXED: rx_buf
                if (byte_idx == 5) begin
                    // All 5 bytes received, verify checksum
                    if (rx_data == (rx_buf[0]^rx_buf[1]^rx_buf[2]^rx_buf[3])) begin  // FIXED: rx_buf
                        v0 <= rx_buf[0];   // FIXED: rx_buf
                        v1 <= rx_buf[1];   // FIXED: rx_buf
                        v2 <= rx_buf[2];   // FIXED: rx_buf
                        v3 <= rx_buf[3];   // FIXED: rx_buf
                        data_ready <= 1;
                    end
                    byte_idx <= 0;
                end else
                    byte_idx <= byte_idx + 1;
            end
        end
    end
endmodule