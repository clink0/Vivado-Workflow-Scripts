module SSDisp_tb(clk, an, seg, dp, sw);
input clk;
reg [3:0] sw;
output [6:0] seg;
output [3:0] an;
output dp;

SSDisp DUT(.clk(clk), .an(an), .seg(seg), .dp(dp), .sw(sw));

endmodule
