module uart_ctrl_tx(clk, send, data, uart_tx, ready);

input clk;
input send;
input [7:0] data;
output reg uart_tx;
output reg ready;

parameter IDLE=2'b00, START=2'b01, SEND=2'b10, STOP_BIT=2'b11;
parameter BAUD_DIV = 10416;

reg [1:0] state = IDLE;
reg [13:0] cnt = 0;
reg [3:0] bit_index = 0;
reg [7:0] shift_reg;

always @(posedge clk)
begin
  case (state)
    IDLE:
      begin
        uart_tx <= 1;
        ready <= 1;
        if (send)
        begin
          shift_reg <= data;
          state <= START;
          ready <= 0;
          cnt <= 0;
        end
      end
    START:
      begin
        uart_tx <= 0;
        if (cnt == BAUD_DIV - 1)
        begin
          cnt <= 0;
          bit_index <= 0;
          state <= SEND;
        end
        else cnt <= cnt + 1;
      end
    SEND:
      begin
        uart_tx <= shift_reg[bit_index];
        if (cnt == BAUD_DIV - 1)
        begin
          cnt <= 0;
          if (bit_index == 7)
            state <= STOP_BIT;
          else
            bit_index <= bit_index + 1;
        end
        else cnt <= cnt + 1;
      end
    STOP_BIT:
      begin
        uart_tx <= 1;
        if (cnt == BAUD_DIV - 1)
        begin
          cnt <= 0;
          state <= IDLE;
          ready <= 1;
        end
        else cnt <= cnt + 1;
      end
  endcase
end

endmodule
