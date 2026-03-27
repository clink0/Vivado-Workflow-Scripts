// Lab 8 T3 - Square problem with 7-seg, 16-bit LEDs, and LCD hex display
// Extends T2 by adding LCD Pmod output via JA (data) and JB (control)
//
// LCD output ports (PicoBlaze writes these):
//   port 0x06: LCD buffer index (0-15, which character position)
//   port 0x07: LCD buffer data  (ASCII character to store)
//
// LCD Pmod wiring:
//   JA[7:0] -> LCD 8-bit data bus
//   JB[0]   -> LCD enable (en)
//   JB[2]   -> LCD register select (rs): 1=data, 0=command
//   JB[1], JB[7:3] tied to 0

module pico_btn_top(
    input  wire        clk,
    input  wire        btnC,       // reset
    input  wire        btnL,       // btn[0]: clear
    input  wire        btnR,       // btn[1]: store switch value
    input  wire [7:0]  sw,
    output wire [3:0]  an,
    output wire [6:0]  seg,
    output wire        dp,
    output wire [15:0] led,
    output wire [7:0]  JA,         // LCD data bus
    output wire [7:0]  JB          // LCD control
);

    // KCPSM6 / ROM signals
    wire [11:0] address;
    wire [17:0] instruction;
    wire        bram_enable;
    wire [7:0]  port_id;
    wire [7:0]  out_port;
    reg  [7:0]  in_port;
    wire        write_strobe;
    wire        k_write_strobe;
    wire        read_strobe;
    wire        interrupt_ack;
    wire        rdl;

    // Internal 7-seg bus {dp, g, f, e, d, c, b, a}
    wire [7:0] sseg_w;
    assign seg = sseg_w[6:0];
    assign dp  = sseg_w[7];

    // I/O output registers
    reg [3:0] en_d;
    reg [7:0] ds3_reg, ds2_reg, ds1_reg, ds0_reg;
    reg [7:0] led_lsb_reg, led_msb_reg;
    assign led = {led_msb_reg, led_lsb_reg};

    // Button flag signals
    wire set_btnc_flag, set_btns_flag;
    reg  btnc_flag_reg, btns_flag_reg;
    wire btnc_flag_next, btns_flag_next;
    wire clr_btn_flag;

    // LCD buffer and control
    reg [7:0] lcd_buf [0:15];
    reg [3:0] lcd_wr_addr;
    reg [7:0] lcd_data_in;
    reg [3:0] lcd_idx;
    integer   lcd_cnt;
    reg       lcd_wr_en;
    wire [7:0] lcd_data_out;
    wire       lcd_en, lcd_rs;

    assign JA         = lcd_data_out;
    assign JB[0]      = lcd_en;
    assign JB[1]      = 1'b0;
    assign JB[2]      = lcd_rs;
    assign JB[7:3]    = 5'b0;

    // =====================================================
    // I/O modules
    // =====================================================
    disp_mux disp_unit
       (.clk(clk), .reset(btnC),
        .in3(ds3_reg), .in2(ds2_reg), .in1(ds1_reg),
        .in0(ds0_reg), .an(an), .sseg(sseg_w));

    debounce btnc_unit
       (.clk(clk), .reset(btnC), .sw(btnL),
        .db_level(), .db_tick(set_btnc_flag));

    debounce btns_unit
       (.clk(clk), .reset(btnC), .sw(btnR),
        .db_level(), .db_tick(set_btns_flag));

    // =====================================================
    // KCPSM6 and ROM instantiation
    // =====================================================
    kcpsm6 #(
        .interrupt_vector        (12'h3FF),
        .scratch_pad_memory_size (64),
        .hwbuild                 (8'h00))
    processor (
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
        .interrupt_ack  (interrupt_ack),
        .reset          (rdl),
        .sleep          (1'b0),
        .clk            (clk)
    );

    btn_rom #(
        .C_FAMILY             ("7S"),
        .C_RAM_SIZE_KWORDS    (1),
        .C_JTAG_LOADER_ENABLE (1))
    program_rom (
        .rdl         (rdl),
        .enable      (bram_enable),
        .address     (address),
        .instruction (instruction),
        .clk         (clk)
    );

    // LCD driver instance (from Lab6T3)
    LCD_driver lcd_unit (
        .clk     (clk),
        .wr_en   (lcd_wr_en),
        .data_in (lcd_data_in),
        .data_out(lcd_data_out),
        .en      (lcd_en),
        .rs      (lcd_rs)
    );

    // =====================================================
    // LCD buffer write from PicoBlaze
    //   port 0x06: latch the buffer index
    //   port 0x07: write ASCII char to lcd_buf[index]
    // =====================================================
    always @(posedge clk) begin
        if (write_strobe && port_id == 8'h06)
            lcd_wr_addr <= out_port[3:0];
        if (write_strobe && port_id == 8'h07)
            lcd_buf[lcd_wr_addr] <= out_port;
    end

    // =====================================================
    // LCD cycling: send each buffer char to LCD_driver
    // 200000 cycles @ 100MHz = 2ms per character
    // 16 chars x 2ms = 32ms refresh (~31 Hz)
    // =====================================================
    initial begin
        lcd_idx  = 0;
        lcd_cnt  = 0;
        lcd_wr_en = 0;
    end

    always @(posedge clk) begin
        if (lcd_cnt >= 200000) begin
            lcd_cnt     <= 0;
            lcd_wr_en   <= 1;
            lcd_data_in <= lcd_buf[lcd_idx];
            if (lcd_idx == 15)
                lcd_idx <= 0;
            else
                lcd_idx <= lcd_idx + 1;
        end else begin
            lcd_cnt   <= lcd_cnt + 1;
            lcd_wr_en <= 0;
        end
    end

    // =====================================================
    // Output interface
    //   0x00-0x03: 7-seg digits ds0-ds3
    //   0x04:      led[7:0]
    //   0x05:      led[15:8]
    //   0x06:      LCD index  (handled above)
    //   0x07:      LCD char   (handled above)
    // =====================================================
    always @(posedge clk) begin
        if (en_d[0]) ds0_reg <= out_port;
        if (en_d[1]) ds1_reg <= out_port;
        if (en_d[2]) ds2_reg <= out_port;
        if (en_d[3]) ds3_reg <= out_port;
        if (write_strobe && port_id == 8'h04) led_lsb_reg <= out_port;
        if (write_strobe && port_id == 8'h05) led_msb_reg <= out_port;
    end

    always @*
        if (write_strobe)
            case (port_id[1:0])
                2'b00: en_d = (port_id[7:2] == 0) ? 4'b0001 : 4'b0000;
                2'b01: en_d = (port_id[7:2] == 0) ? 4'b0010 : 4'b0000;
                2'b10: en_d = (port_id[7:2] == 0) ? 4'b0100 : 4'b0000;
                2'b11: en_d = (port_id[7:2] == 0) ? 4'b1000 : 4'b0000;
            endcase
        else
            en_d = 4'b0000;

    // =====================================================
    // Input interface
    //   0x00: flags {6'b0, btns_flag, btnc_flag}
    //   0x01: sw[7:0]
    // =====================================================
    always @(posedge clk) begin
        btnc_flag_reg <= btnc_flag_next;
        btns_flag_reg <= btns_flag_next;
    end

    assign btnc_flag_next = set_btnc_flag ? 1'b1 :
                            clr_btn_flag  ? 1'b0 :
                            btnc_flag_reg;
    assign btns_flag_next = set_btns_flag ? 1'b1 :
                            clr_btn_flag  ? 1'b0 :
                            btns_flag_reg;

    assign clr_btn_flag = read_strobe && (port_id[0] == 1'b0);

    always @*
        case (port_id[0])
            1'b0: in_port = {6'b0, btns_flag_reg, btnc_flag_reg};
            1'b1: in_port = sw;
        endcase

endmodule
