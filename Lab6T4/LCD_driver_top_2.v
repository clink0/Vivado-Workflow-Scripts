module LCD_driver_top (
    clk,
    sw,
    JB,
    JA
);

  input clk;
  input [15:0] sw;
  output [7:0] JB;
  output [7:0] JA;

  parameter clk_param = 16000000;  //How long is it? 16000000 counts/100000000 counts/s = 0.16 s

  reg [7:0] data[15:0];
  reg [7:0] data_in;
  //wire [7:0] data_in;
  integer counter = 0;
  reg [3:0] index = 0;
  reg wr_en = 0;
  reg [7:0] A_decimal;
  reg [7:0] B_decimal;
  reg [7:0] Eqsign;
  reg [7:0] Result;
  wire [3:0] Calc_data;


  LCD_driver_2 lcd1 (
      .clk(clk),
      .wr_en(wr_en),
      .data_in(data_in),
      .data_out(JA),
      .en(JB[0]),
      .rs(JB[2])
  );

  adder adder1 (
      .clk(clk),
      .B(sw[5:3]),
      .A(sw[2:0]),
      .data(Calc_data)
  );

  always @(posedge clk) begin
    if (counter >= clk_param) begin
      counter <= 0;
      wr_en   <= 1'b1;
      data_in <= data[index];
      index   <= index + 1'b1;
    end else begin
      counter <= counter + 1;
      wr_en   <= 0;
    end
  end

  always @(posedge clk) begin
    data[0]  <= B_decimal;
    data[1]  <= "+";
    data[2]  <= A_decimal;
    data[3]  <= Eqsign;
    data[4]  <= Result;
    data[5]  <= " ";
    data[6]  <= " ";
    data[7]  <= " ";
    data[8]  <= " ";
    data[9]  <= " ";
    data[10] <= " ";
    data[11] <= " ";
    data[12] <= " ";
    data[13] <= " ";
    data[14] <= " ";
    data[15] <= " ";
    case (sw[2:0])
      3'b000: A_decimal <= "0";
      3'b001: A_decimal <= "1";
      3'b010: A_decimal <= "2";
      3'b011: A_decimal <= "3";
    endcase

    case (sw[5:3])
      3'b000: B_decimal <= "0";
      3'b001: B_decimal <= "1";
      3'b010: B_decimal <= "2";
      3'b011: B_decimal <= "3";
    endcase

    if (sw[15]) begin
      Eqsign <= "=";
      case (Calc_data)
        4'b0000: Result <= "0";
        4'b0001: Result <= "1";
        4'b0010: Result <= "2";
        4'b0011: Result <= "3";
        4'b0100: Result <= "4";
        4'b0101: Result <= "5";
        4'b0110: Result <= "6";
        4'b0111: Result <= "7";
      endcase
    end else begin
      Eqsign <= " ";
      Result <= " ";
    end
  end
endmodule
