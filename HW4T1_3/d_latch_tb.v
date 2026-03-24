`timescale 1ns / 1ps
module D_latch_tb;
reg d,c;
wire q,qn;
D_latch UUT(.d(d),.c(c),.q(q),.qn(qn));
initial begin
        {d,c} = 2'b11; #10;
        {d,c} = 2'b01; #10;
        {d,c} = 2'b10; #10;
        {d,c} = 2'b00; #10;
end
endmodule
