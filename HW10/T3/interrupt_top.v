// HW10 T3 - PicoBlaze interrupt: JA[0] rising edge counts on 7-segment (0-F)
// JA[0] (0.5 Hz, 0-3.3V function generator) -> 3-stage synchronizer -> rising-edge detect
// ISR: toggle LED (port 0x00), increment counter to 7-segment (port 0x01)
// No debouncer needed: function generator has clean transitions

module interrupt_top(
    input  wire        CLK100MHZ,
    input  wire [7:0]  JA,         // JA[0] = external pulse input
    output wire [15:0] led,
    output wire [6:0]  seg,
    output wire        dp,
    output wire [3:0]  an
);

    // -------------------------------------------------------
    // 1. JA[0] Synchronization (3-stage shift register)
    // Signals from function generator must be synchronized to FPGA clock.
    // Rising edge detected when ja_sync[1]=1 and ja_sync[2]=0.
    // -------------------------------------------------------
    reg [2:0] ja_sync     = 3'b000;
    reg       interrupt_reg = 0;

    wire interrupt_ack;

    always @(posedge CLK100MHZ) begin
        ja_sync <= {ja_sync[1:0], JA[0]};  // 3-stage synchronizer

        if (interrupt_ack)
            interrupt_reg <= 0;             // Clear when PicoBlaze acknowledges
        else if (ja_sync[1] && !ja_sync[2]) // Rising edge detected
            interrupt_reg <= 1;
    end

    // -------------------------------------------------------
    // 2. Output Port Logic
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
    // 3. 7-Segment Decoder (active-low segments)
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
    assign dp  = 1'b1;      // decimal point off
    assign an  = 4'b1110;   // rightmost digit only

    // -------------------------------------------------------
    // 4. PicoBlaze Core (KCPSM6)
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
    // 5. Program ROM (generated from prog.psm)
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
