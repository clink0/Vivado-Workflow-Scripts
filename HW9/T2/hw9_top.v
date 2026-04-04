`timescale 1ns / 1ps
// HW9 T2 - XADC reads Easy Pulse Sensor (vauxp6/vauxn6), streams via SPI to Arduino
// JB[0]=SCK, JB[1]=SS(active low), JB[2]=MOSI
// Arduino: Pin2=SCK, Pin12=SS, Pin13=MOSI; reads 8-bit ADC value via Serial Plotter
// Sends top 8 bits of 12-bit ADC result (~100Hz)

module hw9_top(
    input  CLK100MHZ,
    input  vauxp6, vauxn6,
    input  vp_in,  vn_in,
    output [2:0] JB     // JB[0]=SCK, JB[1]=SS, JB[2]=MOSI
);
    // ---- XADC ----
    wire        eoc;
    wire [15:0] adc_raw;
    wire        drdy;

    xadc_wiz_0 xadc_inst (
        .daddr_in   (7'h16),        // auxiliary channel 6 (vauxp6/vauxn6)
        .dclk_in    (CLK100MHZ),
        .den_in     (eoc),
        .di_in      (16'b0),
        .dwe_in     (1'b0),
        .busy_out   (),
        .vauxp6     (vauxp6), .vauxn6 (vauxn6),
        .vp_in      (vp_in),  .vn_in  (vn_in),
        .alarm_out  (),
        .do_out     (adc_raw),
        .eoc_out    (eoc),
        .channel_out(),
        .drdy_out   (drdy)
    );

    // Latch top 8 bits of ADC result when data is ready
    // XADC output is left-aligned: bits[15:4] = 12-bit value, bits[3:0] = 0
    // adc_raw[15:8] gives the most significant 8 bits of the conversion
    reg [7:0] adc_byte = 0;
    always @(posedge CLK100MHZ)
        if (drdy) adc_byte <= adc_raw[15:8];

    // ---- Periodic SPI transmit (~100 Hz, every 1,000,000 cycles) ----
    reg [19:0] timer      = 0;
    reg        send_latch = 0;
    wire       busy;

    always @(posedge CLK100MHZ) begin
        if (timer == 20'd999999) begin
            timer <= 0;
            if (!busy) send_latch <= 1;
        end else
            timer <= timer + 1;

        if (busy) send_latch <= 0;
    end

    // ---- SPI Leader ----
    wire sck, ss_n, mosi;

    SPI_leader_transmitter spi_leader (
        .clk  (CLK100MHZ),
        .send (send_latch),
        .data (adc_byte),
        .sck  (sck),
        .ss   (ss_n),
        .mosi (mosi),
        .busy (busy)
    );

    assign JB[0] = sck;
    assign JB[1] = ss_n;
    assign JB[2] = mosi;

endmodule
