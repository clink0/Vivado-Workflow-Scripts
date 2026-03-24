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

  assign data = {c2final, S};

  always @(posedge clk) begin

    AA[0] <= A[0] ^ cm1;
    AA[1] <= A[1] ^ cm1;
    AA[2] <= A[2] ^ cm1;

    c0 <= ((AA[0] | B[0]) & cm1) | (AA[0] & B[0]);
    c1 <= ((AA[1] | B[1]) & c0) | (AA[1] & B[1]);
    c2 <= ((AA[2] | B[2]) & c1) | (AA[2] & B[2]);

    // Sum Logic
    S[0] <= AA[0] ^ B[0] ^ cm1;
    S[1] <= AA[1] ^ B[1] ^ c0;
    S[2] <= AA[2] ^ B[2] ^ c1;

    OV <= c1 ^ c2;
    c2final <= (~OV & S[2]) | (OV & (~S[2]) & c2);
  end
endmodule
