// USB_keyboard_uart_app - Task 2
// Reads PS/2 keyboard scan codes and sends ASCII to serial terminal via UART
// System diagram: Keyboard -> PIC MCU -> PS2Clk/PS2Data
//                 -> keyboard_ctrl.v (USB_keyboard) -> received[25:0]
//                 -> scancode_to_ascii -> ascii[7:0]
//                 -> uart_ctrl_tx -> RsTx (USB serial)
module USB_keyboard_uart_app(clk, PS2Clk, PS2Data, RsTx, led);

input clk;
input PS2Clk;
input PS2Data;
output RsTx;
output [7:0] led;

localparam PRESS=2'b00, EXTEND=2'b01, RLS=2'b10, CHECK=2'b11;

reg [1:0] state = PRESS;
reg [23:0] received;
wire ready;
wire [7:0] data;
reg [7:0] ledreg=0;
reg ready_prev;

// UART control signals
wire uart_ready;
reg uart_send = 0;
reg [7:0] uart_data;
wire [7:0] ascii_out;

// Submodule instantiations
USB_keyboard kb1(
  .ps2data(PS2Data),
  .ps2clk(PS2Clk),
  .data(data),
  .ready(ready)
);

scancode_to_ascii ascii_conv(
  .scancode(received[7:0]),
  .ascii(ascii_out)
);

uart_ctrl_tx uart_tx(
  .clk(clk),
  .send(uart_send),
  .data(uart_data),
  .uart_tx(RsTx),
  .ready(uart_ready)
);

always @ (posedge clk)
begin
  ready_prev <= ready;
  uart_send <= 0; // default: not sending

  case (state)
    PRESS:
      if (ready_prev==0 && ready==1)
      begin
        received[23:16] <= data;
        state <= EXTEND;
      end
    EXTEND:
      if (ready_prev==0 && ready==1)
      begin
        received[15:8] <= data;
        state <= RLS;
      end
RLS:
  if (received[15:8] != 8'hF0)
    state <= EXTEND;
  else if (ready_prev==0 && ready==1)
  begin
    received[7:0] <= data;
    state <= CHECK;
  end
    CHECK:
      begin
        // Toggle LEDs for keys 1-8 (same as Task 1)
        case (received[7:0])
          8'h16: ledreg[0] <= ~ledreg[0]; // toggle if 1 is pressed
          8'h1E: ledreg[1] <= ~ledreg[1]; // toggle if 2 is pressed
          8'h26: ledreg[2] <= ~ledreg[2]; // toggle if 3 is pressed
          8'h25: ledreg[3] <= ~ledreg[3]; // toggle if 4 is pressed
          8'h2E: ledreg[4] <= ~ledreg[4]; // toggle if 5 is pressed
          8'h36: ledreg[5] <= ~ledreg[5]; // toggle if 6 is pressed
          8'h3D: ledreg[6] <= ~ledreg[6]; // toggle if 7 is pressed
          8'h3E: ledreg[7] <= ~ledreg[7]; // toggle if 8 is pressed
        endcase
        // Send ASCII over UART if UART is ready
        if (uart_ready)
        begin
          uart_data <= ascii_out;
          uart_send <= 1;
        end
        state <= PRESS;
      end
  endcase
end

assign led = ledreg;

endmodule
