// Lab 8 T2 - Square problem with 16-bit LED output
// Extends T1: aabb_lsb -> led[7:0], aabb_msb -> led[15:8]
// dp on digit 3 lights when carry-out (result > 16 bits)
//
// Output port map (in addition to T1 sseg ports):
//   port 0x04: led[7:0]  (aabb_lsb)
//   port 0x05: led[15:8] (aabb_msb)

module pico_btn_top(
    input  wire        clk,
    input  wire        btnC,       // reset
    input  wire        btnL,       // btn[0]: clear
    input  wire        btnR,       // btn[1]: store
    input  wire [7:0]  sw,
    output wire [3:0]  an,
    output wire [6:0]  seg,
    output wire        dp,
    output wire [15:0] led
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

    // =====================================================
    // Output interface
    //   0x00-0x03: 7-seg digits ds0-ds3
    //   0x04:      led[7:0]  (aabb_lsb)
    //   0x05:      led[15:8] (aabb_msb)
    // =====================================================
    always @(posedge clk) begin
        if (en_d[0]) ds0_reg     <= out_port;
        if (en_d[1]) ds1_reg     <= out_port;
        if (en_d[2]) ds2_reg     <= out_port;
        if (en_d[3]) ds3_reg     <= out_port;
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
