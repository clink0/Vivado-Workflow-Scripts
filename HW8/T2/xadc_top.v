`timescale 1ns / 1ps
// HW8 T2 - XADC Demo using student-created XADC IP
// Functionally identical to the official XADCdemo.v
// Uses xadc_wiz_0 generated via Vivado IP Catalog (create_ip in build script)
//
// sw[1:0] selects analog channel to display:
//   00 = vauxp6/n6  (XA1, JXADC pin 1)
//   01 = vauxp7/n7  (XA3, JXADC pin 3)
//   10 = vauxp14/n14 (XA2, JXADC pin 2)
//   11 = vauxp15/n15 (XA4, JXADC pin 4)
//
// 7-seg shows voltage as decimal (e.g. 0.500 = 500mV)
// led[15:0] shows bar graph based on top 4 bits of ADC result

module xadc_top(
    input  CLK100MHZ,
    input  vauxp6,  input vauxn6,
    input  vauxp7,  input vauxn7,
    input  vauxp15, input vauxn15,
    input  vauxp14, input vauxn14,
    input  vp_in,   input vn_in,
    input  [1:0] sw,
    output reg [15:0] led,
    output [3:0] an,
    output dp,
    output [6:0] seg
);

    wire        enable;
    wire        ready;
    wire [15:0] data;
    reg  [6:0]  Address_in;

    // 7-seg state machine
    reg [32:0] count;
    localparam S_IDLE       = 0;
    localparam S_FRAME_WAIT = 1;
    localparam S_CONVERSION = 2;
    reg [1:0]  state = S_IDLE;
    reg [15:0] sseg_data;

    // bin2dec signals
    reg        b2d_start;
    reg [15:0] b2d_din;
    wire [15:0] b2d_dout;
    wire        b2d_done;

    // XADC instantiation
    // eoc_out -> den_in for continuous conversion
    xadc_wiz_0 XLXI_7 (
        .daddr_in  (Address_in),
        .dclk_in   (CLK100MHZ),
        .den_in    (enable),
        .di_in     (16'b0),
        .dwe_in    (1'b0),
        .busy_out  (),
        .vauxp6    (vauxp6),  .vauxn6  (vauxn6),
        .vauxp7    (vauxp7),  .vauxn7  (vauxn7),
        .vauxp14   (vauxp14), .vauxn14 (vauxn14),
        .vauxp15   (vauxp15), .vauxn15 (vauxn15),
        .vn_in     (vn_in),
        .vp_in     (vp_in),
        .alarm_out (),
        .do_out    (data),
        .eoc_out   (enable),
        .channel_out(),
        .drdy_out  (ready)
    );

    // LED bar graph: top 4 bits of ADC data determine how many LEDs light
    always @(posedge CLK100MHZ) begin
        if (ready) begin
            case (data[15:12])
                1:  led <= 16'b11;
                2:  led <= 16'b111;
                3:  led <= 16'b1111;
                4:  led <= 16'b11111;
                5:  led <= 16'b111111;
                6:  led <= 16'b1111111;
                7:  led <= 16'b11111111;
                8:  led <= 16'b111111111;
                9:  led <= 16'b1111111111;
                10: led <= 16'b11111111111;
                11: led <= 16'b111111111111;
                12: led <= 16'b1111111111111;
                13: led <= 16'b11111111111111;
                14: led <= 16'b111111111111111;
                15: led <= 16'b1111111111111111;
                default: led <= 16'b1;
            endcase
        end
    end

    // Binary to decimal conversion state machine (updates every 10M cycles ~100ms)
    always @(posedge CLK100MHZ) begin
        case (state)
            S_IDLE: begin
                state <= S_FRAME_WAIT;
                count <= 'b0;
            end
            S_FRAME_WAIT: begin
                if (count >= 10000000) begin
                    if (data > 16'hFFD0) begin
                        sseg_data <= 16'h1000;
                        state     <= S_IDLE;
                    end else begin
                        b2d_start <= 1'b1;
                        b2d_din   <= data;
                        state     <= S_CONVERSION;
                    end
                end else
                    count <= count + 1'b1;
            end
            S_CONVERSION: begin
                b2d_start <= 1'b0;
                if (b2d_done) begin
                    sseg_data <= b2d_dout;
                    state     <= S_IDLE;
                end
            end
        endcase
    end

    bin2dec m_b2d (
        .clk   (CLK100MHZ),
        .start (b2d_start),
        .din   (b2d_din),
        .done  (b2d_done),
        .dout  (b2d_dout)
    );

    // Channel select via switches
    always @(posedge CLK100MHZ) begin
        case (sw)
            0: Address_in <= 7'h16;
            1: Address_in <= 7'h17;
            2: Address_in <= 7'h1e;
            3: Address_in <= 7'h1f;
        endcase
    end

    DigitToSeg segment1 (
        .in1  (sseg_data[3:0]),
        .in2  (sseg_data[7:4]),
        .in3  (sseg_data[11:8]),
        .in4  (sseg_data[15:12]),
        .in5  (),
        .in6  (),
        .in7  (),
        .in8  (),
        .mclk (CLK100MHZ),
        .an   (an),
        .dp   (dp),
        .seg  (seg)
    );

endmodule
