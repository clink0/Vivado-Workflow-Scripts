module SSDispFLC_tb(clk, an, seg, dp);
input clk;
output [6:0] seg;
output [3:0] an;
output dp;

SSDispFLC DUT(.clk(clk), .an(an), .seg(seg), .dp(dp));

endmodule
