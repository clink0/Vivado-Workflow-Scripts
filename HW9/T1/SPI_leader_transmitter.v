module SPI_leader_transmitter (clk, data, send, sck, ss, mosi, busy);
  parameter data_length = 8;
  input clk;
  input [data_length-1:0] data;
  input send;
  output reg sck = 0;
  output reg ss = 1;
  output reg mosi;
  output reg busy = 0;

  localparam RDY = 2'b00, START = 2'b01, TRANSMIT = 2'b10, STOP = 2'b11;
  reg [1:0] state = RDY;
  reg [7:0] clkdiv = 0;
  reg [7:0] index = 0;

  // SCK = 2MHz from 100MHz system clock (toggle every 25 cycles)
  always @(posedge clk) begin
    if (clkdiv == 8'd25) begin
      clkdiv <= 0;
      sck <= ~sck;
    end else clkdiv <= clkdiv + 1;
  end

  always @(negedge sck) begin
    case (state)
      RDY: begin
        if (send) begin
          state <= START;
          busy  <= 1;
          index <= data_length - 1;
        end
      end
      START: begin
        ss    <= 0;
        mosi  <= data[index];
        index <= index - 1;
        state <= TRANSMIT;
      end
      TRANSMIT: begin
        if (index == 0) begin
          state <= STOP;
          mosi  <= data[index];
        end else begin
          mosi  <= data[index];
          index <= index - 1;
        end
      end
      STOP: begin
        ss    <= 1;
        busy  <= 0;
        state <= RDY;
      end
    endcase
  end
endmodule
