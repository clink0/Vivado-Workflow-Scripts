// SPI ALS Reader - reads from PmodALS (ADC081S021) via SPI Mode 3
// CPOL=1, CPHA=1: SCK idles HIGH, data sampled on FALLING edge
//
// PmodALS on JB:
//   JB[0] = CS  (active low)
//   JB[1] = SDO (MISO from sensor)
//   JB[2] = SCK
//
// Packet: 16 SCK cycles
//   Bits [15:12] = null/leading zeros (ignored)
//   Bits [11:4]  = 8-bit light value (MSB first)
//   Bits [3:0]   = trailing zeros (ignored)
//
// Triggers a new read every ~100ms (10,000,000 cycles at 100MHz)

module spi_als_reader(
    input  wire       clk,
    input  wire       miso,     // JB[1] SDO from ALS
    output reg        sck,      // JB[2]
    output reg        cs,       // JB[0] active low
    output reg [7:0]  light,    // 8-bit light value
    output reg        ready     // pulses high for one clk when new data available
);

    // SCK = 2MHz: toggle every 25 cycles
    reg [7:0]  clkdiv  = 0;
    reg        sck_int = 1;     // idles HIGH (Mode 3)

    // State machine
    localparam IDLE = 2'b00, START = 2'b01, READ = 2'b10, DONE = 2'b11;
    reg [1:0]  state   = IDLE;
    reg [4:0]  bit_cnt = 0;
    reg [15:0] shift   = 0;

    // Periodic trigger: ~100ms
    reg [23:0] period  = 0;
    reg        trigger = 0;

    // Generate SCK (always running, gated by cs)
    always @(posedge clk) begin
        if (clkdiv == 8'd24) begin
            clkdiv  <= 0;
            sck_int <= ~sck_int;
        end else begin
            clkdiv <= clkdiv + 1;
        end
    end

    // Periodic trigger
    always @(posedge clk) begin
        if (period == 24'd9_999_999) begin
            period  <= 0;
            trigger <= 1;
        end else begin
            period  <= period + 1;
            trigger <= 0;
        end
    end

    // SCK output: idles high when idle, runs during transaction
    always @(*) begin
        if (state == IDLE || state == DONE)
            sck = 1'b1;
        else
            sck = sck_int;
    end

    // Main state machine — transitions on falling edge of sck_int
    always @(negedge sck_int) begin
        ready <= 0;
        case (state)
            IDLE: begin
                if (trigger) begin
                    cs      <= 0;
                    bit_cnt <= 15;
                    shift   <= 0;
                    state   <= START;
                end
            end
            START: begin
                // First falling edge after CS low — begin sampling on next posedge
                state <= READ;
            end
            READ: begin
                // Sample happens on posedge (below); just count here
                if (bit_cnt == 0)
                    state <= DONE;
                else
                    bit_cnt <= bit_cnt - 1;
            end
            DONE: begin
                cs    <= 1;
                // bits [11:4] of the 16-bit capture = 8-bit light value
                light <= shift[11:4];
                ready <= 1;
                state <= IDLE;
            end
        endcase
    end

    // Sample MISO on rising edge of sck_int
    always @(posedge sck_int) begin
        if (state == READ || state == START)
            shift <= {shift[14:0], miso};
    end

endmodule
