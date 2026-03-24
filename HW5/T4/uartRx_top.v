module UART_rx_top(clk, RsRx, seg, an, dp);
  input clk, RsRx;
  output [6:0] seg;
  output [3:0] an;
  output dp;

  // RX_RDY: wait for data_ready to go low (new transfer starting)
  // RX_WAIT: wait for data_ready to go high (transfer complete)
  // RX_DATARDY: latch data onto display if it is a valid digit 0-9
  localparam RX_RDY = 2'b00, RX_WAIT = 2'b01, RX_DATARDY = 2'b10;
  reg [1:0] state = RX_RDY;

  wire data_ready;
  wire [7:0] out;
  wire parity;
  wire error;

  // digit shown on display, default to blank (all segments off = 4'hF)
  reg [3:0] digit = 4'hF;

  UART_rx_ctrl #(19200) RX(.clk(clk), .rx(RsRx), .data(out), .parity(parity),
    .ready(data_ready), .error(error));

  display display_UT(.clk(clk), .data(digit), .seg(seg), .an(an), .dp(dp));

  always @(posedge clk)
  case (state)
  RX_RDY:
    if (!data_ready) state <= RX_WAIT;
  RX_WAIT:
    if (data_ready) state <= RX_DATARDY;
  RX_DATARDY:
  begin
    // ASCII '0' = 8'h30, ASCII '9' = 8'h39
    // Subtract 8'h30 to get the numeric digit value
    if (!error && out >= 8'h30 && out <= 8'h39)
      digit <= out - 8'h30;
    state <= RX_RDY;
  end
  endcase
endmodule
