module adder (
input clk,
input [2:0] A,
input [2:0] B,
input cm1,
output reg OV,
output reg [3:0] data
);
wire [2:0] AA;
wire c0, c1, c2;
wire [2:0] S;

assign AA[0] = A[0]^cm1;
assign AA[1] = A[1]^cm1;
assign AA[2] = A[2]^cm1;

assign c0 = (AA[0]&B[0]) | (AA[0]|B[0])&cm1;
assign c1 = (AA[1]&B[1]) | (AA[1]|B[1])&c0;
assign c2 = (AA[2]&B[2]) | (AA[2]|B[2])&c1;

assign S[0] = AA[0]^B[0]^cm1;
assign S[1] = AA[1]^B[1]^c0;
assign S[2] = AA[2]^B[2]^c1;

always @(posedge clk)
begin
  OV   <= c2^c1;
  data <= {c2,S[2:0]};
end
endmodule
