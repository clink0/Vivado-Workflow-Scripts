// HW7 T2 - Smart Light Controller
// PmodALS on JB: JB[0]=CS, JB[1]=SDO(MISO), JB[2]=SCK
// PicoBlaze reads 8-bit light value, drives led[15:0]
// Brighter = fewer LEDs on; darker = all LEDs on

module als_top(
    input  wire        clk,
    input  wire        btnC,       // reset (wired to kcpsm6 via rdl)
    input  wire [2:0]  JB,         // JB[0]=CS out, JB[1]=MISO in, JB[2]=SCK out
    output wire [15:0] led,
    output wire        JB_cs,      // JB[0] CS
    output wire        JB_sck      // JB[2] SCK
);

    // JB input (MISO)
    wire miso = JB[1];

    // SPI ALS reader outputs
    wire       spi_cs, spi_sck;
    wire [7:0] light;
    wire       spi_ready;

    spi_als_reader als_reader (
        .clk   (clk),
        .miso  (miso),
        .sck   (spi_sck),
        .cs    (spi_cs),
        .light (light),
        .ready (spi_ready)
    );

    assign JB_cs  = spi_cs;
    assign JB_sck = spi_sck;

    // Latch light value and ready flag for PicoBlaze
    reg [7:0] light_reg  = 0;
    reg       ready_reg  = 0;

    always @(posedge clk) begin
        if (spi_ready) light_reg <= light;
        ready_reg <= spi_ready;
    end

    // KCPSM6 signals
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

    als_rom #(
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

    // Input interface
    //   port 0x00: {7'b0, spi_ready}
    //   port 0x01: light_reg
    always @(*) begin
        case (port_id[0])
            1'b0: in_port = {7'b0, ready_reg};
            1'b1: in_port = light_reg;
        endcase
    end

    // Output interface
    //   port 0x00: led[7:0]
    //   port 0x01: led[15:8]
    reg [7:0] led_lsb = 0;
    reg [7:0] led_msb = 0;

    always @(posedge clk) begin
        if (write_strobe && port_id == 8'h00) led_lsb <= out_port;
        if (write_strobe && port_id == 8'h01) led_msb <= out_port;
    end

    assign led = {led_msb, led_lsb};

endmodule
