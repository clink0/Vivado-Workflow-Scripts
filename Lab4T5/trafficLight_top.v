module trafficLight_top(clk, led, sw);
  input clk;
  input [0:0] sw;
  output [5:0] led;
  
  trafficLight DUT(.clk(clk), .light(led[5:0]), .sw(sw[0]));

endmodule
