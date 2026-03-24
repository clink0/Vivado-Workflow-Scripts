
`timescale 1ns / 1ps
module JK_flip_flop_tb;
reg j,k,clr,clk;
wire q,qn;
integer i;

JK_flip_flop UUT(.j(j),.k(k),.clr(clr),.clk(clk),.q(q),.qn(qn));

initial begin
  clk = 0; clr = 1; j = 0; k = 0;
  // Test J=1,K=0 (Set)
  {j,k} = 2'b10; #20;
  // Test J=0,K=1 (Reset)
  {j,k} = 2'b01; #20;
  // Test J=1,K=1 (Toggle)
  {j,k} = 2'b11; #20;
  {j,k} = 2'b11; #20;
  // Test J=0,K=0 (Hold)
  {j,k} = 2'b00; #20;
  // Test clear (active low)
  clr = 0; #20;
  clr = 1; #20;
end

always #10 clk = ~clk;

endmodule
