`timescale 1ns / 1ps
// SPI byte transmitter for SSD1306 OLED — SPI Mode 0 (CPOL=0, CPHA=0)
// SPI clock = CLK / (2 * HALF_DIV) = 100MHz / 50 = 2 MHz
module OledSPI(
    input  wire       CLK,
    input  wire       RST,
    input  wire       SND,     // 1-cycle strobe to start 8-bit transfer
    input  wire [7:0] DATA,
    input  wire       DC_IN,   // 0=command, 1=data
    output reg        CS,      // chip select (active low)
    output reg        SDIN,    // MOSI
    output reg        SCLK,
    output reg        DC,
    output reg        DONE     // 1-cycle pulse when transfer complete
);
    localparam HALF = 25;      // half-period in CLK cycles

    reg       active;
    reg [4:0] ck;              // divider counter (0..HALF-1)
    reg       phase;           // 0 = low half,  1 = high half
    reg [2:0] bit_cnt;         // bits remaining (7 down to 0)
    reg [7:0] sr;              // shift register

    always @(posedge CLK) begin
        DONE <= 0;
        if (RST) begin
            CS <= 1; SCLK <= 0; SDIN <= 0; DC <= 0;
            active <= 0; ck <= 0; phase <= 0; bit_cnt <= 7; sr <= 0;
        end else if (!active) begin
            CS <= 1; SCLK <= 0;
            if (SND) begin
                sr <= DATA; DC <= DC_IN;
                bit_cnt <= 7; ck <= 0; phase <= 0;
                CS <= 0; SDIN <= DATA[7];
                active <= 1;
            end
        end else begin
            if (ck == HALF - 1) begin
                ck    <= 0;
                phase <= ~phase;
                if (!phase) begin                   // rising edge
                    SCLK <= 1;
                end else begin                      // falling edge
                    SCLK <= 0;
                    if (bit_cnt == 0) begin
                        CS     <= 1;
                        DONE   <= 1;
                        active <= 0;
                    end else begin
                        bit_cnt <= bit_cnt - 1;
                        sr      <= {sr[6:0], 1'b0};
                        SDIN    <= sr[6];           // next MSB
                    end
                end
            end else
                ck <= ck + 1;
        end
    end
endmodule
