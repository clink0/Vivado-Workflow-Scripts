`timescale 1ns / 1ps
// PmodOLEDCtrl_top — Basys3 top module for Pmod OLED (SSD1306, 128x32)
// Connects Basys3 clock + btnC to the OLED controller and JB pins.
//
// JB pin mapping:
//   JB1  A14 → CS        JB7  A15 → DC
//   JB2  A16 → SDIN      JB8  A17 → RES
//   JB4  B16 → SCLK      JB9  C15 → VBAT
//   (JB3 B15 = NC)        JB10 C16 → VDD
//
// btnC resets the display controller and restarts the init sequence.
module PmodOLEDCtrl_top(
    input  wire CLK100MHZ,
    input  wire btnC,       // active-high reset
    // Pmod JB pins
    output wire CS,
    output wire SDIN,
    output wire SCLK,
    output wire DC,
    output wire RES,
    output wire VBAT,
    output wire VDD
);
    wire rst = btnC;

    // ── Top-level FSM ─────────────────────────────────────────────────────
    reg state;
    localparam S_INIT    = 1'b0,
               S_DISPLAY = 1'b1;

    wire init_fin;
    always @(posedge CLK100MHZ) begin
        if (rst)                        state <= S_INIT;
        else if (state == S_INIT && init_fin) state <= S_DISPLAY;
    end

    // ── SPI signal mux ────────────────────────────────────────────────────
    wire spi_done;
    wire init_snd, ex_snd;
    wire [7:0] init_data, ex_data;
    wire init_dc, ex_dc;

    wire spi_snd  = (state == S_INIT) ? init_snd  : ex_snd;
    wire [7:0] spi_data = (state == S_INIT) ? init_data : ex_data;
    wire spi_dc   = (state == S_INIT) ? init_dc   : ex_dc;

    // ── OledSPI ───────────────────────────────────────────────────────────
    OledSPI spi_ctrl(
        .CLK    (CLK100MHZ),
        .RST    (rst),
        .SND    (spi_snd),
        .DATA   (spi_data),
        .DC_IN  (spi_dc),
        .CS     (CS),
        .SDIN   (SDIN),
        .SCLK   (SCLK),
        .DC     (DC),
        .DONE   (spi_done)
    );

    // ── OledInit ──────────────────────────────────────────────────────────
    OledInit init_mod(
        .CLK      (CLK100MHZ),
        .RST      (rst),
        .EN       (state == S_INIT),
        .DONE_SPI (spi_done),
        .SND      (init_snd),
        .DATA     (init_data),
        .DC       (init_dc),
        .RES      (RES),
        .VBAT     (VBAT),
        .VDD      (VDD),
        .FIN      (init_fin)
    );

    // ── charLib font ROM ──────────────────────────────────────────────────
    wire [10:0] charlib_addr;
    wire [7:0]  charlib_dout;

    charLib font_rom(
        .clk  (CLK100MHZ),
        .addr (charlib_addr),
        .dout (charlib_dout)
    );

    // ── OledEX ────────────────────────────────────────────────────────────
    wire ex_fin;
    OledEX ex_mod(
        .CLK          (CLK100MHZ),
        .RST          (rst),
        .EN           (state == S_DISPLAY),
        .DONE_SPI     (spi_done),
        .charlib_dout (charlib_dout),
        .charlib_addr (charlib_addr),
        .SND          (ex_snd),
        .DATA         (ex_data),
        .DC           (ex_dc),
        .FIN          (ex_fin)
    );

endmodule
