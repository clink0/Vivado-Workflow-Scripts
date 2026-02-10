module adder (
    clk,
    cm1,
    A,
    B,
    data,
    OV
);
  input clk, cm1;
  input [2:0] A;
  input [2:0] B;
  output reg OV;
  output [3:0] data;
  reg [2:0] S;
  reg c2, c1, c0;
  reg [2:0] AA;
  reg c2final;

  always @(posedge clk) begin
    AA[0] <= A[0] ^ cm1;
    AA[1] <= A[1] ^ cm1;
    AA[2] <= A[2] ^ cm1;
    c0 <= ((AA[0] | B[0]) & cm1) | (AA[0] & B[0]);
    c1 <= ((AA[1] | B[1]) & c0) | (AA[1] & B[1]);
    c2 <= ((AA[2] | B[2]) & c1) | (AA[2] & B[2]);
    S[0] <= AA[0] ^ B[0] ^ cm1;
    S[1] <= AA[1] ^ B[1] ^ c0;
    S[2] <= AA[2] ^ B[2] ^ c1;
    OV <= c1 ^ c2;
    c2final <= ~OV & (S[2]) | (OV & (~S[2]) & c2);
  end
endmodule

module disp (
    clk,
    dp,
    seg,
    an,
    data
);
  input clk;
  input [3:0] data;
  output reg [6:0] seg;
  output reg [1:0] an = 2'b01;
  output dp;
  parameter cntmax = 65000;
  reg [15:0] cnt;
  assign dp = 1'b1;

  always @(posedge clk) begin
    if (cnt >= cntmax) begin
      cnt <= 0;
      an  <= {};  // Note: This line appears incomplete in the screenshot
    end else cnt <= cnt + 1;
  end

  always@(posedge clk) // Note: Typo 'posede' in original image corrected to 'posedge'
begin
    if (an == 2'b01 & data[3] == 1) begin
      seg <= 7'b0111111;  //G_to_a, display a negative sign
    end else if (an == 2'b01 & data[3] == 0) seg <= 7'b1111111;
    else if (an == 2'b10) begin
      case (data)
        4'b0000: seg <= 7'bxxxxxxx;
        4'b0001: seg <= 7'b1001111;  //G_A 1: 1001111
        4'b1111: seg <= 7'b1001111;  //G_A 1: 1001111
      endcase
    end
  end
endmodule

