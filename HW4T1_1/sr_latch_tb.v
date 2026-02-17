`timescale 1ns / 1ps
module SR_latch_tb;
reg s,r;
wire q,qn;
SR_latch UUT(.s(s),.r(r),.q(q),.qn(qn));
initial begin
        {s,r} = 2'b10; #10;
        {s,r} = 2'b01; #10;
end
endmodule
