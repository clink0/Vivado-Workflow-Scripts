
`timescale 1ns / 1ps
module T_flip_flop_tb;
reg t,clk,clr;
wire q,qn;
integer i;

T_flip_flop UUT(.t(t),.clk(clk),.clr(clr),.q(q),.qn(qn));

initial begin
  clk = 0; clr = 1; t = 0;
  // Test T=0 (Hold)
  t = 0; #40;
  // Test T=1 (Toggle)
  t = 1; #20;
  t = 1; #20;
  t = 1; #20;
  t = 1; #20;
  // Test T=0 (Hold)
  t = 0; #40;
  // Test clear (active low)
  clr = 0; #20;
  clr = 1; #20;
  // Toggle again after clear
  t = 1; #20;
  t = 1; #20;
end

always #10 clk = ~clk;

endmodule
