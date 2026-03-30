// SPI ALS Reader - reads from PmodALS (ADC081S021) via SPI Mode 3
// CPOL=1, CPHA=1: SCK idles HIGH, data sampled on FALLING edge of SCK
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
// All logic in a single posedge clk always block to avoid multiple drivers.
// SCK edges detected via a one-cycle-delayed copy (sck_d).

module spi_als_reader(
    input  wire       clk,
    input  wire       miso,
    output reg        sck   = 1,
    output reg        cs    = 1,
    output reg [7:0]  light = 0,
    output reg        ready = 0
);

    // SCK generator: toggle every 25 cycles = 2MHz, idles HIGH
    reg [7:0] clkdiv = 0;
    reg       sck_r  = 1;   // free-running SCK register
    reg       sck_d  = 1;   // one-cycle delay for edge detection

    // Falling edge of sck_r detected one cycle after it happens
    wire sck_falling = sck_d & ~sck_r;

    // State machine
    localparam IDLE = 2'b00, ACTIVE = 2'b01, DONE = 2'b10;
    reg [1:0]  state   = IDLE;
    reg [3:0]  bit_cnt = 0;
    reg [15:0] shift_r = 0;

    // Periodic trigger: ~100ms (10,000,000 cycles at 100MHz)
    reg [23:0] period  = 0;
    reg        trigger = 0;

    always @(posedge clk) begin
        // SCK generation
        sck_d <= sck_r;
        if (clkdiv == 8'd24) begin
            clkdiv <= 0;
            sck_r  <= ~sck_r;
        end else begin
            clkdiv <= clkdiv + 1;
        end

        // Periodic trigger
        ready   <= 0;
        trigger <= 0;
        if (period == 24'd9_999_999) begin
            period  <= 0;
            trigger <= 1;
        end else begin
            period <= period + 1;
        end

        case (state)
            IDLE: begin
                sck <= 1'b1;
                cs  <= 1'b1;
                // Only start when SCK is high so CS asserts while SCK=1 (Mode 3 requirement)
                if (trigger && sck_r) begin
                    cs      <= 1'b0;
                    bit_cnt <= 4'd15;
                    shift_r <= 16'b0;
                    state   <= ACTIVE;
                end
            end

            ACTIVE: begin
                sck <= sck_r;
                // Sample MISO on each falling edge of SCK
                if (sck_falling) begin
                    shift_r <= {shift_r[14:0], miso};
                    if (bit_cnt == 4'd0) begin
                        state <= DONE;
                    end else begin
                        bit_cnt <= bit_cnt - 1;
                    end
                end
            end

            DONE: begin
                sck   <= 1'b1;
                cs    <= 1'b1;
                light <= shift_r[11:4];
                ready <= 1'b1;
                state <= IDLE;
            end
        endcase
    end

endmodule
