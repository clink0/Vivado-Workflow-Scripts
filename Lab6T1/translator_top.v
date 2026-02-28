module translator_top (
    clk,
    btnC,
    sw,
    JB,
    JA
);

  input clk;
  input btnC;
  input [7:0] sw;
  output [7:0] JA;
  output [7:0] JB;

  parameter clk_param = 16000000;

  reg [7:0] data[15:0];
  reg [7:0] character;
  wire [7:0] data_in;
  integer counter = 0;
  reg [3:0] index = 0;

  reg wr_en = 0;

  wire en;
  wire rs;
  wire [7:0] data_out;

  assign JA = data_out;
  assign JB[0] = en;
  assign JB[2] = rs;

  LCD_driver lcd1 (
      .clk(clk),
      .reset(btnC),
      .wr_en(wr_en),
      .data_in(data_in),
      .data_out(data_out),
      .en(en),
      .rs(rs)
  );

  assign data_in = character;

  always @(posedge clk) begin
    if (btnC) counter <= 0;
    else begin
      if (counter == clk_param) counter <= 0;
      else counter <= counter + 1;
    end
  end

  always @(posedge clk) begin
    if (btnC) begin
      wr_en <= 0;
      index <= 0;
    end else begin
      if (counter == clk_param) begin
        wr_en <= 1'b1;
        character <= data[index];
        index <= index + 1'b1;
      end else wr_en <= 0;
    end
  end

  always @(posedge clk)
    case (sw)
      8'h01: begin
        data[0]  <= "A";
        data[1]  <= "C";
        data[2]  <= "C";
        data[3]  <= "I";
        data[4]  <= "O";
        data[5]  <= "N";
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
      end
      8'h02: begin
        data[0]  <= "M";
        data[1]  <= "O";
        data[2]  <= "V";
        data[3]  <= "I";
        data[4]  <= "M";
        data[5]  <= "I";
        data[6]  <= "E";
        data[7]  <= "N";
        data[8]  <= "T";
        data[9]  <= "O";
        data[10] <= " ";
        data[11] <= " ";
        data[12] <= " ";
        data[13] <= " ";
        data[14] <= " ";
        data[15] <= " ";
      end
      8'h04: begin
        data[0]  <= "G";
        data[1]  <= "I";
        data[2]  <= "R";
        data[3]  <= "O";
        data[4]  <= " ";
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
      end
      8'h08: begin
        data[0]  <= "C";
        data[1]  <= "O";
        data[2]  <= "R";
        data[3]  <= "R";
        data[4]  <= "E";
        data[5]  <= "R";
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
      end
      8'h10: begin
        data[0]  <= "M";
        data[1]  <= "I";
        data[2]  <= "R";
        data[3]  <= "A";
        data[4]  <= "R";
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
      end
      8'h20: begin
        data[0]  <= "A";
        data[1]  <= "T";
        data[2]  <= "A";
        data[3]  <= "Q";
        data[4]  <= "U";
        data[5]  <= "E";
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
      end
      8'h40: begin
        data[0]  <= "D";
        data[1]  <= "E";
        data[2]  <= "T";
        data[3]  <= "E";
        data[4]  <= "N";
        data[5]  <= "E";
        data[6]  <= "R";
        data[7]  <= " ";
        data[8]  <= " ";
        data[9]  <= " ";
        data[10] <= " ";
        data[11] <= " ";
        data[12] <= " ";
        data[13] <= " ";
        data[14] <= " ";
        data[15] <= " ";
      end
      8'h80: begin
        data[0]  <= "H";
        data[1]  <= "O";
        data[2]  <= "L";
        data[3]  <= "A";
        data[4]  <= " ";
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
      end
      default: begin
        data[0]  <= "H";
        data[1]  <= "A";
        data[2]  <= "S";
        data[3]  <= " ";
        data[4]  <= "U";
        data[5]  <= "N";
        data[6]  <= "A";
        data[7]  <= " ";
        data[8]  <= "E";
        data[9]  <= "L";
        data[10] <= "E";
        data[11] <= "C";
        data[12] <= "C";
        data[13] <= "I";
        data[14] <= "O";
        data[15] <= "N";
      end
    endcase

endmodule
