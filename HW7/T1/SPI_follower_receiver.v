module SPI_follower_receiver(sck, ss, mosi, data, busy, ready);
  parameter data_length = 8;
  input sck;
  input ss;
  input mosi;
  output reg [data_length-1:0] data;
  output reg busy  = 0;
  output reg ready = 0;

  localparam RDY = 2'b00, RECEIVE = 2'b01, STOP = 2'b10;
  reg [1:0] state = RDY;
  reg [data_length-1:0] data_temp = 0;
  reg [7:0] index = data_length - 1;

  always @(posedge sck) begin
    case (state)
      RDY: begin
        if (!ss) begin
          data_temp[index] <= mosi;
          index <= index - 1;
          busy  <= 1;
          ready <= 0;
          state <= RECEIVE;
        end
      end
      RECEIVE: begin
        if (index == 0) begin
          data_temp[index] <= mosi;
          state <= STOP;
        end else begin
          data_temp[index] <= mosi;
          index <= index - 1;
        end
      end
      STOP: begin
        data  <= data_temp;
        busy  <= 0;
        ready <= 1;
        state <= RDY;
        index <= data_length - 1;
      end
    endcase
  end
endmodule
