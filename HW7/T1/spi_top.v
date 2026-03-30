// HW7 T1 - SPI loopback demo
// Leader transmits sw[7:0] on btnR press; follower receives via internal wires.
// led[7:0]  = received data
// led[8]    = leader busy
// led[9]    = follower ready

module spi_top(
    input  wire        clk,
    input  wire        btnC,    // reset
    input  wire        btnR,    // send trigger
    input  wire [7:0]  sw,
    output wire [15:0] led
);

    // Internal SPI bus (loopback)
    wire sck, ss, mosi;
    wire leader_busy;
    wire [7:0] rx_data;
    wire follower_busy, follower_ready;

    // Latch send high on btnR press, hold until leader goes busy
    // (a 1-cycle pulse would be missed by the 2MHz negedge sck)
    reg btnR_prev  = 0;
    reg send_latch = 0;
    wire send = send_latch;

    always @(posedge clk) begin
        btnR_prev <= btnR;
        if (btnR & ~btnR_prev)
            send_latch <= 1;
        else if (leader_busy)
            send_latch <= 0;
    end

    SPI_leader_transmitter #(.data_length(8)) leader (
        .clk  (clk),
        .data (sw),
        .send (send),
        .sck  (sck),
        .ss   (ss),
        .mosi (mosi),
        .busy (leader_busy)
    );

    SPI_follower_receiver #(.data_length(8)) follower (
        .sck   (sck),
        .ss    (ss),
        .mosi  (mosi),
        .data  (rx_data),
        .busy  (follower_busy),
        .ready (follower_ready)
    );

    // Latch received data so it stays visible after transaction ends
    reg [7:0] rx_latch = 0;
    always @(posedge clk)
        if (follower_ready) rx_latch <= rx_data;

    assign led[7:0]  = rx_latch;
    assign led[8]    = leader_busy;
    assign led[9]    = follower_ready;
    assign led[15:10] = 6'b0;

endmodule
