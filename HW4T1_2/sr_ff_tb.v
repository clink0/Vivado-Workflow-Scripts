`timescale 1ns / 1ps
module SR_latch_tb;
reg s,r,clk;
wire q,qn;
SR_FF UUT(.s(s),.r(r),.clk(clk),.q(q),.qn(qn));
initial begin
        {s,r,clk} = 3'b101; #10;
        {s,r,clk} = 3'b001; #10;
        {r,s,clk} = 3'b101; #10;
        {s,r,clk} = 3'b001; #10;
end
endmodule
