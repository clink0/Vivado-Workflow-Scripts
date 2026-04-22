`timescale 1ns / 1ps
// SSD1306 initialization state machine for Pmod OLED (128x32)
// Controls power rails (VDD, VBAT), reset pin (RES), and sends init commands via SPI.
// VDD and VBAT outputs drive active-low FETs on the Pmod board (0 = power ON).
module OledInit(
    input  wire       CLK,
    input  wire       RST,
    input  wire       EN,       // held high while this module is the active driver
    input  wire       DONE_SPI, // 1-cycle pulse from OledSPI
    output reg        SND,
    output reg  [7:0] DATA,
    output reg        DC,
    output reg        RES,
    output reg        VBAT,
    output reg        VDD,
    output reg        FIN       // 1-cycle pulse: init complete
);
    // Delay constants at 100 MHz
    localparam MS1   = 24'd100_000;
    localparam MS10  = 24'd1_000_000;
    localparam MS100 = 24'd10_000_000;

    reg [7:0]  step;
    reg [23:0] dly;

    always @(posedge CLK) begin
        SND <= 0; FIN <= 0;
        if (RST || !EN) begin
            step <= 0; dly <= 0;
            RES <= 1; VBAT <= 1; VDD <= 1;
        end else case (step)
            // ── Power-up sequence ───────────────────────────────
            // 0: VDD on (active-low FET)
            8'd0: begin VDD <= 0; step <= 1; end
            // 1: Wait 1 ms
            8'd1: begin
                if (dly == MS1 - 1) begin dly <= 0; step <= 2; end
                else dly <= dly + 1;
            end
            // 2-3: Send display off (AE)
            8'd2:  begin DC <= 0; DATA <= 8'hAE; SND <= 1; step <= 3; end
            8'd3:  begin if (DONE_SPI) step <= 4; end
            // 4: RES low
            8'd4:  begin RES <= 0; step <= 5; end
            // 5: Wait 1 ms
            8'd5: begin
                if (dly == MS1 - 1) begin dly <= 0; step <= 6; end
                else dly <= dly + 1;
            end
            // 6: RES high
            8'd6:  begin RES <= 1; step <= 7; end
            // 7: Wait 10 ms
            8'd7: begin
                if (dly == MS10 - 1) begin dly <= 0; step <= 8; end
                else dly <= dly + 1;
            end
            // 8: VBAT on
            8'd8:  begin VBAT <= 0; step <= 9; end
            // 9: Wait 100 ms
            8'd9: begin
                if (dly == MS100 - 1) begin dly <= 0; step <= 10; end
                else dly <= dly + 1;
            end

            // ── Init command sequence ────────────────────────────
            // Charge pump enable
            8'd10: begin DC<=0; DATA<=8'h8D; SND<=1; step<=11; end
            8'd11: begin if(DONE_SPI) step<=12; end
            8'd12: begin DC<=0; DATA<=8'h14; SND<=1; step<=13; end
            8'd13: begin if(DONE_SPI) step<=14; end

            // Display clock divide / oscillator frequency
            8'd14: begin DC<=0; DATA<=8'hD5; SND<=1; step<=15; end
            8'd15: begin if(DONE_SPI) step<=16; end
            8'd16: begin DC<=0; DATA<=8'h80; SND<=1; step<=17; end
            8'd17: begin if(DONE_SPI) step<=18; end

            // Multiplex ratio = 31 (32 rows)
            8'd18: begin DC<=0; DATA<=8'hA8; SND<=1; step<=19; end
            8'd19: begin if(DONE_SPI) step<=20; end
            8'd20: begin DC<=0; DATA<=8'h1F; SND<=1; step<=21; end
            8'd21: begin if(DONE_SPI) step<=22; end

            // Display offset = 0
            8'd22: begin DC<=0; DATA<=8'hD3; SND<=1; step<=23; end
            8'd23: begin if(DONE_SPI) step<=24; end
            8'd24: begin DC<=0; DATA<=8'h00; SND<=1; step<=25; end
            8'd25: begin if(DONE_SPI) step<=26; end

            // Display start line = 0
            8'd26: begin DC<=0; DATA<=8'h40; SND<=1; step<=27; end
            8'd27: begin if(DONE_SPI) step<=28; end

            // Segment remap (col 127 -> SEG 0, mirrors horizontally)
            8'd28: begin DC<=0; DATA<=8'hA1; SND<=1; step<=29; end
            8'd29: begin if(DONE_SPI) step<=30; end

            // COM output scan direction remapped
            8'd30: begin DC<=0; DATA<=8'hC8; SND<=1; step<=31; end
            8'd31: begin if(DONE_SPI) step<=32; end

            // COM pins hardware config: sequential, no left/right remap (32-row)
            8'd32: begin DC<=0; DATA<=8'hDA; SND<=1; step<=33; end
            8'd33: begin if(DONE_SPI) step<=34; end
            8'd34: begin DC<=0; DATA<=8'h02; SND<=1; step<=35; end
            8'd35: begin if(DONE_SPI) step<=36; end

            // Contrast control
            8'd36: begin DC<=0; DATA<=8'h81; SND<=1; step<=37; end
            8'd37: begin if(DONE_SPI) step<=38; end
            8'd38: begin DC<=0; DATA<=8'hCF; SND<=1; step<=39; end
            8'd39: begin if(DONE_SPI) step<=40; end

            // Pre-charge period
            8'd40: begin DC<=0; DATA<=8'hD9; SND<=1; step<=41; end
            8'd41: begin if(DONE_SPI) step<=42; end
            8'd42: begin DC<=0; DATA<=8'hF1; SND<=1; step<=43; end
            8'd43: begin if(DONE_SPI) step<=44; end

            // VCOMH deselect level
            8'd44: begin DC<=0; DATA<=8'hDB; SND<=1; step<=45; end
            8'd45: begin if(DONE_SPI) step<=46; end
            8'd46: begin DC<=0; DATA<=8'h40; SND<=1; step<=47; end
            8'd47: begin if(DONE_SPI) step<=48; end

            // Memory addressing mode = Page (0x02)
            8'd48: begin DC<=0; DATA<=8'h20; SND<=1; step<=49; end
            8'd49: begin if(DONE_SPI) step<=50; end
            8'd50: begin DC<=0; DATA<=8'h02; SND<=1; step<=51; end
            8'd51: begin if(DONE_SPI) step<=52; end

            // Entire display on (from RAM contents)
            8'd52: begin DC<=0; DATA<=8'hA4; SND<=1; step<=53; end
            8'd53: begin if(DONE_SPI) step<=54; end

            // Normal display (not inverted)
            8'd54: begin DC<=0; DATA<=8'hA6; SND<=1; step<=55; end
            8'd55: begin if(DONE_SPI) step<=56; end

            // Display on
            8'd56: begin DC<=0; DATA<=8'hAF; SND<=1; step<=57; end
            8'd57: begin if(DONE_SPI) step<=58; end

            // Done
            8'd58: begin FIN <= 1; end

            default: step <= 0;
        endcase
    end
endmodule
