
`timescale 1ns / 1ps
module D_flip_flop_tb;
reg d=0; // NEITHER input reg d=0; NOR input reg d;
reg clr=1; // NEITHER input reg clr=0; NOR input reg clr;
reg clk=0; // NEITHER input reg clk=0; NOR input reg clk;
wire q,qn; // NOT output q,qn;
integer i;

D_flip_flop UUT(.d(d),.clk(clk),.clr(clr),.q(q),.qn(qn));

initial begin
  for(i=0;i<20;i=i+1)begin
          clk=~clk;
          if(i>3 & i<10) d=1;
          if(i==15) clr=0;
          #10;
  end
end
endmodule
