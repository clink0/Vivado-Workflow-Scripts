// HW10 T1 - PicoBlaze interrupt: button press toggles LED[0]
// btnC (U18) -> debouncer -> rising-edge detect -> PicoBlaze interrupt
// ISR: XOR LED[0] and output to port 0x00

module interrupt_top(
    input  wire        CLK100MHZ,
    input  wire        btnC,       // interrupt button
    output wire [15:0] led
);

    // -------------------------------------------------------
    // 1. De-bouncer (~10ms at 100 MHz = 1,000,000 cycles)
    // -------------------------------------------------------
    reg [19:0] db_count   = 0;
    reg        btn_clean  = 0;

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
            interrupt_reg <= 0;         // Clear when PicoBlaze acknowledges
        else if (btn_clean && !btn_prev)
            interrupt_reg <= 1;         // Set on rising edge
    end

    // -------------------------------------------------------
    // 3. Output Port Logic (LEDs)
    // -------------------------------------------------------
    wire [7:0] out_port;
    wire [7:0] port_id;
    wire       write_strobe;

    reg [7:0] led_out_reg = 8'h00;

    always @(posedge CLK100MHZ) begin
        if (write_strobe && port_id == 8'h00)
            led_out_reg <= out_port;
    end

    assign led[7:0]  = led_out_reg;
    assign led[15:8] = 8'h00;

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
