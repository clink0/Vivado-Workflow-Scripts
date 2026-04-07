// HW10 T2 - PicoBlaze interrupt: button press toggles LED[0] and counts 0-F on 7-segment
// btnC (U18) -> debouncer -> rising-edge detect -> PicoBlaze interrupt
// ISR: toggle LED (port 0x00), increment counter to 7-segment (port 0x01)

module interrupt_top(
    input  wire        CLK100MHZ,
    input  wire        btnC,
    output wire [15:0] led,
    output wire [6:0]  seg,
    output wire        dp,
    output wire [3:0]  an
);

    // -------------------------------------------------------
    // 1. De-bouncer (~10ms at 100 MHz = 1,000,000 cycles)
    // -------------------------------------------------------
    reg [19:0] db_count  = 0;
    reg        btn_clean = 0;

    always @(posedge CLK100MHZ) begin
        if (btnC == btn_clean)
            db_count <= 0;
        else begin
            db_count <= db_count + 1;
            if (db_count == 20'd1_000_000)
                btn_clean <= btnC;
        end
    end

    // -------------------------------------------------------
    // 2. Edge Detection & Interrupt Handshake
    // -------------------------------------------------------
    reg btn_prev      = 0;
    reg interrupt_reg = 0;

    wire interrupt_ack;

    always @(posedge CLK100MHZ) begin
        btn_prev <= btn_clean;

        if (interrupt_ack)
            interrupt_reg <= 0;
        else if (btn_clean && !btn_prev)
            interrupt_reg <= 1;
    end

    // -------------------------------------------------------
    // 3. Output Port Logic
    // -------------------------------------------------------
    wire [7:0] out_port;
    wire [7:0] port_id;
    wire       write_strobe;

    reg [7:0] led_out_reg = 8'h00;
    reg [7:0] seg_out_reg = 8'h00;

    always @(posedge CLK100MHZ) begin
        if (write_strobe) begin
            if (port_id == 8'h00) led_out_reg <= out_port;
            if (port_id == 8'h01) seg_out_reg <= out_port;
        end
    end

    assign led[7:0]  = led_out_reg;
    assign led[15:8] = 8'h00;

    // -------------------------------------------------------
    // 4. 7-Segment Decoder (active-low segments, ABCDEFG order)
    // Converts lower 4 bits of seg_out_reg to segment pattern
    // -------------------------------------------------------
    reg [6:0] seg_data;
    always @(*) begin
        case (seg_out_reg[3:0])
            4'h0: seg_data = 7'b1000000;
            4'h1: seg_data = 7'b1111001;
            4'h2: seg_data = 7'b0100100;
            4'h3: seg_data = 7'b0110000;
            4'h4: seg_data = 7'b0011001;
            4'h5: seg_data = 7'b0010010;
            4'h6: seg_data = 7'b0000010;
            4'h7: seg_data = 7'b1111000;
            4'h8: seg_data = 7'b0000000;
            4'h9: seg_data = 7'b0010000;
            4'hA: seg_data = 7'b0001000;
            4'hB: seg_data = 7'b0000011;
            4'hC: seg_data = 7'b1000110;
            4'hD: seg_data = 7'b0100001;
            4'hE: seg_data = 7'b0000110;
            4'hF: seg_data = 7'b0001110;
            default: seg_data = 7'b1111111;
        endcase
    end

    assign seg = seg_data;
    assign dp  = 1'b1;          // decimal point off (active-low)
    assign an  = 4'b1110;       // rightmost digit only

    // -------------------------------------------------------
    // 5. PicoBlaze Core (KCPSM6)
    // -------------------------------------------------------
    wire [11:0] address;
    wire [17:0] instruction;
    wire        bram_enable;
    wire        k_write_strobe;
    wire        read_strobe;
    wire        rdl;

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
        .in_port        (8'h00),
        .interrupt      (interrupt_reg),
        .interrupt_ack  (interrupt_ack),
        .reset          (rdl),
        .sleep          (1'b0),
        .clk            (CLK100MHZ)
    );

    // -------------------------------------------------------
    // 6. Program ROM (generated from prog.psm)
    // -------------------------------------------------------
    prog #(
        .C_FAMILY             ("7S"),
        .C_RAM_SIZE_KWORDS    (1),
        .C_JTAG_LOADER_ENABLE (0))
    program_rom (
        .rdl         (rdl),
        .enable      (bram_enable),
        .address     (address),
        .instruction (instruction),
        .clk         (CLK100MHZ)
    );

endmodule
