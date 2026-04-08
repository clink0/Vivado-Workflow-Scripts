`timescale 1ns / 1ps
// Simple 8N1 UART transmitter
// Parameters: CLK_HZ (system clock), BAUD (baud rate)
// send: 1-cycle strobe to begin transmitting data[7:0]
// busy: high while transmitting (do not issue send when busy)
module uart_tx #(
    parameter CLK_HZ = 100_000_000,
    parameter BAUD   = 115200
)(
    input  wire       clk,
    input  wire       rst,
    input  wire       send,
    input  wire [7:0] data,
    output reg        busy,
    output reg        tx
);
    localparam DIVIDER = CLK_HZ / BAUD;  // clocks per bit

    reg [31:0] ck;
    reg [3:0]  bit_idx;   // 0=start, 1-8=data, 9=stop
    reg [9:0]  shift_reg; // {stop, data[7:0], start}

    always @(posedge clk) begin
        if (rst) begin
            busy <= 0; tx <= 1; ck <= 0; bit_idx <= 0;
        end else if (!busy) begin
            tx <= 1;
            if (send) begin
                shift_reg <= {1'b1, data, 1'b0}; // stop | data | start
                bit_idx   <= 0;
                ck        <= 0;
                busy      <= 1;
                tx        <= 1'b0; // start bit
            end
        end else begin
            if (ck == DIVIDER - 1) begin
                ck <= 0;
                if (bit_idx == 9) begin
                    busy <= 0; tx <= 1;
                end else begin
                    bit_idx   <= bit_idx + 1;
                    tx        <= shift_reg[bit_idx + 1];
                end
            end else
                ck <= ck + 1;
        end
    end
endmodule
