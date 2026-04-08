`timescale 1ns / 1ps
// HW11 T3 — Pulse Sensor Heart Rate Monitor
// XADC reads analog pulse sensor signal (VAUXP6/VAUXN6).
// Picoblaze measures frequency (BPM) by detecting threshold crossings.
// BPM displayed on Pmod OLED via SSD1306 SPI controller.
// Raw XADC samples sent over UART (115200 baud) for PC waveform plot.
//
// Picoblaze port map:
//   INPUT  0x00 : XADC high byte (8 MSBs of 12-bit result)
//   INPUT  0x01 : ms-timer low  byte
//   INPUT  0x02 : ms-timer high byte
//   INPUT  0x03 : peak-detected flag (bit 0; cleared on read)
//   OUTPUT 0x00 : led[7:0]  (raw XADC value)
//   OUTPUT 0x01 : BPM tens  digit ASCII code → oled screen[2][6]
//   OUTPUT 0x02 : BPM units digit ASCII code → oled screen[2][7]
//   OUTPUT 0x03 : threshold high byte (Picoblaze can tune it)
//
// OLED displays:
//   Row 0 : "  HEART  RATE   "
//   Row 1 : "                "
//   Row 2 : "  BPM:  ??  BPM "   (digits updated by Picoblaze)
//   Row 3 : "                "
module hw11_t3_top(
    input  wire        CLK100MHZ,
    input  wire        btnC,
    // Analog input
    input  wire        vauxp6,
    input  wire        vauxn6,
    input  wire        vp_in,
    input  wire        vn_in,
    // LEDs
    output wire [15:0] led,
    // Pmod JB — OLED
    output wire        CS,
    output wire        SDIN,
    output wire        SCLK,
    output wire        DC,
    output wire        RES,
    output wire        VBAT,
    output wire        VDD,
    // UART TX to PC
    output wire        uart_tx
);
    wire rst = btnC;

    // ══════════════════════════════════════════════════════════════════════
    // XADC
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

    reg [7:0] xadc_hi;   // latched 8 MSBs
    always @(posedge CLK100MHZ)
        if (xadc_drdy) xadc_hi <= xadc_data[15:8];

    // ══════════════════════════════════════════════════════════════════════
    // Millisecond timer (16-bit, wraps at 65535 ms)
    // ══════════════════════════════════════════════════════════════════════
    reg [16:0] ms_prescaler;   // counts to 100,000 cycles
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
    // Peak / threshold crossing detector
    // Threshold is set by Picoblaze (port 0x03).  Hardware detects the
    // rising edge of the pulse (signal crosses threshold upward).
    // ══════════════════════════════════════════════════════════════════════
    reg [7:0]  threshold;
    reg        above_thresh_prev;
    reg        peak_flag;        // set on rising crossing, cleared by Picoblaze read

    // pico_read_thresh: asserted when Picoblaze reads port 0x03 (clears peak_flag)
    // pico_write_thresh: asserted when Picoblaze writes port 0x03 (updates threshold)
    // These wires are forward-declared; Verilog resolves before elaboration.
    wire pico_read_thresh;
    wire pico_write_thresh;

    always @(posedge CLK100MHZ) begin
        if (rst) begin
            threshold <= 8'h80; above_thresh_prev <= 0; peak_flag <= 0;
        end else begin
            // Threshold update from Picoblaze
            if (pico_write_thresh) threshold <= out_port;

            above_thresh_prev <= (xadc_hi >= threshold);

            if ((xadc_hi >= threshold) && !above_thresh_prev)
                peak_flag <= 1;
            else if (pico_read_thresh)  // cleared when Picoblaze reads port 0x03
                peak_flag <= 0;
        end
    end

    // ══════════════════════════════════════════════════════════════════════
    // UART TX — streams raw XADC byte at 115200 baud
    // ══════════════════════════════════════════════════════════════════════
    wire uart_busy;
    wire uart_send;

    // Send a byte every time XADC produces a new sample
    reg xadc_drdy_d;
    always @(posedge CLK100MHZ) xadc_drdy_d <= xadc_drdy;
    assign uart_send = xadc_drdy && !xadc_drdy_d && !uart_busy;

    uart_tx #(.CLK_HZ(100_000_000), .BAUD(115200)) uart_inst(
        .clk   (CLK100MHZ),
        .rst   (rst),
        .send  (uart_send),
        .data  (xadc_hi),
        .busy  (uart_busy),
        .tx    (uart_tx)
    );

    // ══════════════════════════════════════════════════════════════════════
    // Picoblaze I/O
    // ══════════════════════════════════════════════════════════════════════
    wire [7:0]  port_id;
    wire [7:0]  out_port;
    wire        write_strobe, read_strobe, k_write_strobe;
    reg  [7:0]  in_port;
    wire        rdl;

    // Flag: Picoblaze is reading/writing port 0x03 this cycle
    assign pico_read_thresh  = read_strobe  && (port_id == 8'h03);
    assign pico_write_thresh = write_strobe && (port_id == 8'h03);

    always @(*) begin
        case (port_id)
            8'h00: in_port = xadc_hi;
            8'h01: in_port = ms_timer[7:0];
            8'h02: in_port = ms_timer[15:8];
            8'h03: in_port = {7'h0, peak_flag};
            default: in_port = 8'h00;
        endcase
    end

    // LED output register (port 0x00)
    reg [7:0] led_reg;
    always @(posedge CLK100MHZ) begin
        if (rst) led_reg <= 0;
        else if (write_strobe && port_id == 8'h00) led_reg <= out_port;
    end
    assign led[7:0]  = led_reg;
    assign led[15:8] = 8'h00;

    // BPM display registers — drive OLED screen row 2 cols 6 & 7
    reg [7:0] bpm_tens_char;    // ASCII code of tens digit
    reg [7:0] bpm_units_char;   // ASCII code of units digit
    always @(posedge CLK100MHZ) begin
        if (rst) begin bpm_tens_char <= 8'h2D; bpm_units_char <= 8'h2D; end  // '--'
        else if (write_strobe) begin
            if (port_id == 8'h01) bpm_tens_char  <= out_port;
            if (port_id == 8'h02) bpm_units_char <= out_port;
        end
    end

    // ══════════════════════════════════════════════════════════════════════
    // Picoblaze core
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
    // OLED controller (shared SPI, same as T1)
    // ══════════════════════════════════════════════════════════════════════
    reg  oled_state;
    localparam S_INIT = 1'b0, S_DISPLAY = 1'b1;
    wire init_fin;
    always @(posedge CLK100MHZ) begin
        if (rst) oled_state <= S_INIT;
        else if (oled_state == S_INIT && init_fin) oled_state <= S_DISPLAY;
    end

    wire spi_done;
    wire init_snd, ex_snd;
    wire [7:0] init_data, ex_data;
    wire init_dc, ex_dc;

    wire spi_snd  = (oled_state == S_INIT) ? init_snd  : ex_snd;
    wire [7:0] spi_data = (oled_state == S_INIT) ? init_data : ex_data;
    wire spi_dc   = (oled_state == S_INIT) ? init_dc   : ex_dc;

    OledSPI spi_ctrl(
        .CLK(CLK100MHZ), .RST(rst),
        .SND(spi_snd), .DATA(spi_data), .DC_IN(spi_dc),
        .CS(CS), .SDIN(SDIN), .SCLK(SCLK), .DC(DC), .DONE(spi_done)
    );

    OledInit init_mod(
        .CLK(CLK100MHZ), .RST(rst), .EN(oled_state == S_INIT),
        .DONE_SPI(spi_done),
        .SND(init_snd), .DATA(init_data), .DC(init_dc),
        .RES(RES), .VBAT(VBAT), .VDD(VDD), .FIN(init_fin)
    );

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
