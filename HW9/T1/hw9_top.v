`timescale 1ns / 1ps
// HW9 T1 - SPI Leader outputs constant 8'b00001111 for oscilloscope verification
// JB[0]=SCK, JB[1]=SS(active low), JB[2]=MOSI
// Sends one byte every ~1ms continuously

module hw9_top(
    input  CLK100MHZ,
    output [2:0] JB     // JB[0]=SCK, JB[1]=SS, JB[2]=MOSI
);
    // Timer: fire a send pulse every ~1ms (100,000 cycles)
    reg [16:0] timer     = 0;
    reg        send_latch = 0;
    wire       busy;

    always @(posedge CLK100MHZ) begin
        if (timer == 17'd99999) begin
            timer <= 0;
            if (!busy) send_latch <= 1;
        end else
            timer <= timer + 1;

        // Clear latch once the leader picks it up (busy goes high)
        if (busy) send_latch <= 0;
    end

    wire sck, ss_n, mosi;

    SPI_leader_transmitter spi_leader (
        .clk  (CLK100MHZ),
        .send (send_latch),
        .data (8'b00001111),   // constant test pattern
        .sck  (sck),
        .ss   (ss_n),
        .mosi (mosi),
        .busy (busy)
    );

    assign JB[0] = sck;
    assign JB[1] = ss_n;
    assign JB[2] = mosi;

endmodule
