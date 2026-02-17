module SR_FF(s,r,clk,q,qn);
input s,r,clk;
output reg q;
output reg qn;
always @ (s or r or clk)
        if (clk & s) {q,qn} <= 2'b10;
        else if (clk & r) {q,qn} <= 2'b01;
endmodule
