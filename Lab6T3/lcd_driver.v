module LCD_driver_top (
    clk,
    JB,
    JA
);

  input clk;
  output [7:0] JB;
  output [7:0] JA;
  parameter clk_param = 16000000;  // 16000000/100000000 = 0.16 s per character

  reg [7:0] data[15:0];
  reg [7:0] data_in;
  integer counter = 0;
  reg [3:0] index = 0;
  reg wr_en = 0;
  reg done = 0;  // flag: all 16 chars sent once, stop cycling

  LCD_driver lcd1 (
      .clk(clk),
      .wr_en(wr_en),
      .data_in(data_in),
      .data_out(JA),
      .en(JB[0]),
      .rs(JB[2])
  );

  initial begin
    data[0]  = "8'h48";
    data[1]  = "8'h65";
    data[2]  = "8'h6C";
    data[3]  = "8'h6C";
    data[4]  = "8'h6F";
    data[5]  = "8'h20";
    data[6]  = "8'h21";
    data[7]  = "8'h21";
    data[8]  = "8'h20";
    data[9]  = "8'h20";
    data[10] = "8'h20";
    data[11] = "8'h20";
    data[12] = "8'h20";
    data[13] = "8'h20";
    data[14] = "8'h20";
    data[15] = "8'h20";
  end

  always @(posedge clk) begin
    if (!done) begin
      if (counter >= clk_param) begin
        counter <= 0;
        wr_en   <= 1'b1;
        data_in <= data[index];
        if (index == 15) begin
          done  <= 1;  // all characters sent, stop
          index <= 0;
        end else index <= index + 1'b1;
      end else begin
        counter <= counter + 1;
        wr_en   <= 0;
      end
    end else wr_en <= 0;  // no more writes, text stays on screen
  end

endmodule
