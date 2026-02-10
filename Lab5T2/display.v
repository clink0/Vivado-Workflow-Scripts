module display (
    clk,
    dp,
    seg,
    an,
    data
);
  input clk;
  input [3:0] data;
  output reg [6:0] seg;
  output reg [3:0] an = 4'b1101;
  output dp;

  parameter cntmax = 65000;
  reg [15:0] cnt;
  assign dp = 1'b1;

  always @(posedge clk) begin
    if (cnt >= cntmax) begin
      cnt <= 0;
      an  <= {an[3:2], an[0], an[1]};
    end else cnt <= cnt + 1;
  end

  always @(posedge clk) begin
    if (an == 4'b1101) begin
      if (data[3] == 1) seg <= 7'b0111111;
      else seg <= 7'b1111111;
    end else if (an == 4'b1110) begin
      case (data)
        4'b0000: seg <= 7'b1000000;  // 0
        4'b0001: seg <= 7'b1111001;  // 1
        4'b0010: seg <= 7'b0100100;  // 2
        4'b0011: seg <= 7'b0110000;  // 3

        4'b1111: seg <= 7'b1111001;  // -1
        4'b1110: seg <= 7'b0100100;  // -2
        4'b1101: seg <= 7'b0110000;  // -3
        4'b1100: seg <= 7'b0011001;  // -4

        default: seg <= 7'b1111111;  // Blank
      endcase
    end
  end
endmodule

