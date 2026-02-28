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
  parameter clk_param = 16000000;
  reg [7:0] data[15:0];
  reg [7:0] data_in;
  integer counter = 0;
  reg [3:0] index = 0;
  reg wr_en = 0;

  reg [7:0] A_sign, A_mag;
  reg [7:0] B_sign, B_mag;
  reg [7:0] Eqsign;
  reg [7:0] Res_sign, Res_mag;

  wire [3:0] Calc_data;
  wire OV;

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
      .A(sw[2:0]),
      .B(sw[5:3]),
      .cm1(1'b0),
      .data(Calc_data),
      .OV(OV)
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

    case (sw[2:0])
      3'b000: begin A_sign <= " "; A_mag <= "0"; end
      3'b001: begin A_sign <= " "; A_mag <= "1"; end
      3'b010: begin A_sign <= " "; A_mag <= "2"; end
      3'b011: begin A_sign <= " "; A_mag <= "3"; end
      3'b100: begin A_sign <= "-"; A_mag <= "4"; end
      3'b101: begin A_sign <= "-"; A_mag <= "3"; end
      3'b110: begin A_sign <= "-"; A_mag <= "2"; end
      3'b111: begin A_sign <= "-"; A_mag <= "1"; end
    endcase

    case (sw[5:3])
      3'b000: begin B_sign <= " "; B_mag <= "0"; end
      3'b001: begin B_sign <= " "; B_mag <= "1"; end
      3'b010: begin B_sign <= " "; B_mag <= "2"; end
      3'b011: begin B_sign <= " "; B_mag <= "3"; end
      3'b100: begin B_sign <= "-"; B_mag <= "4"; end
      3'b101: begin B_sign <= "-"; B_mag <= "3"; end
      3'b110: begin B_sign <= "-"; B_mag <= "2"; end
      3'b111: begin B_sign <= "-"; B_mag <= "1"; end
    endcase

    if (sw[15]) begin
      Eqsign <= "=";
      case (Calc_data)
        4'b0000: begin Res_sign <= " "; Res_mag <= "0"; end
        4'b0001: begin Res_sign <= " "; Res_mag <= "1"; end
        4'b0010: begin Res_sign <= " "; Res_mag <= "2"; end
        4'b0011: begin Res_sign <= " "; Res_mag <= "3"; end
        4'b0100: begin Res_sign <= " "; Res_mag <= "4"; end
        4'b0101: begin Res_sign <= " "; Res_mag <= "5"; end
        4'b0110: begin Res_sign <= " "; Res_mag <= "6"; end
        4'b0111: begin Res_sign <= " "; Res_mag <= "7"; end
        4'b1000: begin Res_sign <= "-"; Res_mag <= "8"; end
        4'b1001: begin Res_sign <= "-"; Res_mag <= "7"; end
        4'b1010: begin Res_sign <= "-"; Res_mag <= "6"; end
        4'b1011: begin Res_sign <= "-"; Res_mag <= "5"; end
        4'b1100: begin Res_sign <= "-"; Res_mag <= "4"; end
        4'b1101: begin Res_sign <= "-"; Res_mag <= "3"; end
        4'b1110: begin Res_sign <= "-"; Res_mag <= "2"; end
        4'b1111: begin Res_sign <= "-"; Res_mag <= "1"; end
      endcase
    end else begin
      Eqsign   <= " ";
      Res_sign <= " ";
      Res_mag  <= " ";
    end

    data[0]  <= B_sign;
    data[1]  <= B_mag;
    data[2]  <= "+";
    data[3]  <= A_sign;
    data[4]  <= A_mag;
    data[5]  <= Eqsign;
    data[6]  <= Res_sign;
    data[7]  <= Res_mag;
    data[8]  <= " ";
    data[9]  <= " ";
    data[10] <= " ";
    data[11] <= " ";
    data[12] <= " ";
    data[13] <= " ";
    data[14] <= " ";
    data[15] <= " ";
  end

  assign JB[7:3] = 5'b0;
  assign JB[1]   = 1'b0;

endmodule
