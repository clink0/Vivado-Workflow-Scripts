`timescale 1ns / 1ps
// Course Project Task 2 — Picoblaze + XADC → binary display on LEDs
// Probes JXADC analog input (VAUXP6/VAUXN6), reads XADC output via
// Picoblaze, and displays the 8 MSBs on led[7:0] as binary.
//
// Picoblaze I/O ports:
//   INPUT  0x00 : XADC high byte (bits 15:8 of do_out = upper 8 of 12-bit ADC)
//   OUTPUT 0x00 : LED[7:0]
module cp_t2_top(
    input  wire        CLK100MHZ,
    input  wire        btnC,        // reset
    input  wire        vauxp6,      // JXADC XA1_P (J3) — analog positive
    input  wire        vauxn6,      // JXADC XA1_N (K3) — analog negative
    input  wire        vp_in,       // dedicated VP/VN (internally tied on Basys3)
    input  wire        vn_in,
    output wire [15:0] led
);
    wire rst = btnC;

    // ── XADC ──────────────────────────────────────────────────────────────
    wire [15:0] xadc_data;
    wire        xadc_eoc;
    wire        xadc_drdy;

    xadc_wiz_0 xadc_inst(
        .daddr_in   (7'h16),        // channel address for VAUXP6/VAUXN6
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

    // Latch 8 MSBs of XADC result when data is ready
    reg [7:0] xadc_latch;
    always @(posedge CLK100MHZ)
        if (xadc_drdy) xadc_latch <= xadc_data[15:8];

    // ── Picoblaze I/O ──────────────────────────────────────────────────────
    wire [7:0] port_id;
    wire [7:0] out_port;
    wire       write_strobe;
    wire       read_strobe;
    wire [7:0] in_port;

    assign in_port = (port_id == 8'h00) ? xadc_latch : 8'h00;

    reg [7:0] led_reg;
    always @(posedge CLK100MHZ) begin
        if (rst) led_reg <= 0;
        else if (write_strobe && port_id == 8'h00) led_reg <= out_port;
    end
    assign led[7:0]  = led_reg;
    assign led[15:8] = 8'h00;

    // ── Picoblaze core ────────────────────────────────────────────────────
    wire [11:0] address;
    wire [17:0] instruction;
    wire        bram_enable;
    wire        k_write_strobe;
    wire        rdl;

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

endmodule
