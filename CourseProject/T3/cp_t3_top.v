`timescale 1ns / 1ps
// Course Project Task 3 — Pulse Sensor Heart Rate Monitor
// XADC reads raw analog signal from JXADC (VAUXP6/VAUXN6).
// Picoblaze runs adaptive threshold peak detection, measures BPM,
// and displays it on the Pmod OLED (JB).
//
// Picoblaze port map:
//   INPUT  0x00 : XADC high byte (8 MSBs of 12-bit result)
//   INPUT  0x01 : ms-timer low  byte
//   INPUT  0x02 : ms-timer high byte
//   OUTPUT 0x00 : led[7:0]  (raw XADC value for debug)
//   OUTPUT 0x01 : BPM tens  digit ASCII -> OLED row 2 col 8
//   OUTPUT 0x02 : BPM units digit ASCII -> OLED row 2 col 9
//
// OLED layout (4 rows x 16 chars):
//   Row 0 : "  HEART  RATE   "
//   Row 1 : "                "
//   Row 2 : "  BPM:  ??  BPM "   (cols 8-9 updated by Picoblaze)
//   Row 3 : "                "
module cp_t3_top(
    input  wire        CLK100MHZ,
    input  wire        btnC,
    // JXADC — raw analog waveform input
    input  wire        vauxp6,
    input  wire        vauxn6,
    input  wire        vp_in,
    input  wire        vn_in,
    // On-board LEDs
    output wire [15:0] led,
    // Pmod JB — OLED (SSD1306 4-wire SPI)
    output wire        CS,
    output wire        SDIN,
    output wire        SCLK,
    output wire        DC,
    output wire        RES,
    output wire        VBAT,
    output wire        VDD
);
    wire rst = btnC;

    // ══════════════════════════════════════════════════════════════════════
    // XADC — continuous single-channel conversion on VAUXP6/VAUXN6
    // ══════════════════════════════════════════════════════════════════════
    wire [15:0] xadc_data;
    wire        xadc_eoc, xadc_drdy;

    xadc_wiz_0 xadc_inst(
        .daddr_in   (7'h16),
        .dclk_in    (CLK100MHZ),
        .den_in     (xadc_eoc),
        .di_in      (16'h0),
        .dwe_in     (1'b0),
        .busy_out   (),
        .vauxp6     (vauxp6),
        .vauxn6     (vauxn6),
        .vp_in      (vp_in),
        .vn_in      (vn_in),
        .alarm_out  (),
        .do_out     (xadc_data),
        .eoc_out    (xadc_eoc),
        .channel_out(),
        .drdy_out   (xadc_drdy)
    );

    reg [7:0] xadc_hi;
    always @(posedge CLK100MHZ)
        if (xadc_drdy) xadc_hi <= xadc_data[15:8];

    // ══════════════════════════════════════════════════════════════════════
    // Millisecond timer (16-bit, wraps every ~65 s)
    // ══════════════════════════════════════════════════════════════════════
    reg [16:0] ms_prescaler;
    reg [15:0] ms_timer;

    always @(posedge CLK100MHZ) begin
        if (rst) begin ms_prescaler <= 0; ms_timer <= 0; end
        else if (ms_prescaler == 17'd99_999) begin
            ms_prescaler <= 0;
            ms_timer     <= ms_timer + 1;
        end else
            ms_prescaler <= ms_prescaler + 1;
    end

    // ══════════════════════════════════════════════════════════════════════
    // Picoblaze I/O
    // ══════════════════════════════════════════════════════════════════════
    wire [7:0] port_id;
    wire [7:0] out_port;
    wire       write_strobe, read_strobe, k_write_strobe;
    reg  [7:0] in_port;
    wire       rdl;

    always @(*) begin
        case (port_id)
            8'h00:   in_port = xadc_hi;
            8'h01:   in_port = ms_timer[7:0];
            8'h02:   in_port = ms_timer[15:8];
            default: in_port = 8'h00;
        endcase
    end

    // led[7:0] = raw XADC value (written by Picoblaze via port 0x00)
    reg [7:0] led_reg;
    always @(posedge CLK100MHZ) begin
        if (rst) led_reg <= 0;
        else if (write_strobe && port_id == 8'h00) led_reg <= out_port;
    end
    assign led[7:0]  = led_reg;
    assign led[15:8] = 8'h00;

    // BPM digit registers — fed to OledEX_t3 for live OLED update
    reg [7:0] bpm_tens_char;
    reg [7:0] bpm_units_char;
    always @(posedge CLK100MHZ) begin
        if (rst) begin bpm_tens_char <= 8'h2D; bpm_units_char <= 8'h2D; end
        else if (write_strobe) begin
            if (port_id == 8'h01) bpm_tens_char  <= out_port;
            if (port_id == 8'h02) bpm_units_char <= out_port;
        end
    end

    // ══════════════════════════════════════════════════════════════════════
    // Picoblaze core (kcpsm6)
    // ══════════════════════════════════════════════════════════════════════
    wire [11:0] address;
    wire [17:0] instruction;
    wire        bram_enable;

    kcpsm6 #(
        .interrupt_vector        (12'h3FF),
        .scratch_pad_memory_size (64),
        .hwbuild                 (8'h00))
    processor(
        .address        (address),
        .instruction    (instruction),
        .bram_enable    (bram_enable),
        .port_id        (port_id),
        .write_strobe   (write_strobe),
        .k_write_strobe (k_write_strobe),
        .out_port       (out_port),
        .read_strobe    (read_strobe),
        .in_port        (in_port),
        .interrupt      (1'b0),
        .interrupt_ack  (),
        .reset          (rdl),
        .sleep          (1'b0),
        .clk            (CLK100MHZ)
    );

    prog #(
        .C_FAMILY             ("7S"),
        .C_RAM_SIZE_KWORDS    (1),
        .C_JTAG_LOADER_ENABLE (0))
    program_rom(
        .rdl         (rdl),
        .enable      (bram_enable),
        .address     (address),
        .instruction (instruction),
        .clk         (CLK100MHZ)
    );

    // ══════════════════════════════════════════════════════════════════════
    // OLED controller — init then continuous display refresh
    // ══════════════════════════════════════════════════════════════════════
    reg  oled_state;
    localparam S_INIT = 1'b0, S_DISPLAY = 1'b1;
    wire init_fin;
    always @(posedge CLK100MHZ) begin
        if (rst) oled_state <= S_INIT;
        else if (oled_state == S_INIT && init_fin) oled_state <= S_DISPLAY;
    end

    wire       spi_done;
    wire       init_snd, ex_snd;
    wire [7:0] init_data, ex_data;
    wire       init_dc, ex_dc;

    wire       spi_snd  = (oled_state == S_INIT) ? init_snd  : ex_snd;
    wire [7:0] spi_data = (oled_state == S_INIT) ? init_data : ex_data;
    wire       spi_dc   = (oled_state == S_INIT) ? init_dc   : ex_dc;

    OledSPI spi_ctrl(
        .CLK(CLK100MHZ), .RST(rst),
        .SND(spi_snd), .DATA(spi_data), .DC_IN(spi_dc),
        .CS(CS), .SDIN(SDIN), .SCLK(SCLK), .DC(DC), .DONE(spi_done)
    );

    wire res_init, vbat_init, vdd_init;

    OledInit init_mod(
        .CLK(CLK100MHZ), .RST(rst), .EN(oled_state == S_INIT),
        .DONE_SPI(spi_done),
        .SND(init_snd), .DATA(init_data), .DC(init_dc),
        .RES(res_init), .VBAT(vbat_init), .VDD(vdd_init), .FIN(init_fin)
    );

    assign RES  = (oled_state == S_INIT) ? res_init  : 1'b1;
    assign VBAT = (oled_state == S_INIT) ? vbat_init : 1'b0;
    assign VDD  = (oled_state == S_INIT) ? vdd_init  : 1'b0;

    wire [10:0] charlib_addr;
    wire [7:0]  charlib_dout;
    charLib font_rom(.clk(CLK100MHZ), .addr(charlib_addr), .dout(charlib_dout));

    OledEX_t3 ex_mod(
        .CLK(CLK100MHZ), .RST(rst), .EN(oled_state == S_DISPLAY),
        .DONE_SPI(spi_done),
        .charlib_dout(charlib_dout), .charlib_addr(charlib_addr),
        .bpm_tens(bpm_tens_char), .bpm_units(bpm_units_char),
        .SND(ex_snd), .DATA(ex_data), .DC(ex_dc),
        .FIN()
    );

endmodule
