module quiz_top(clk, sw, led);
input clk;
input [2:0] sw;
output [0:0] led;

quiz DUT(.clk(clk), .sw(sw), .led(led));

endmodule
