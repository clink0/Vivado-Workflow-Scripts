module trafficLight_top(clk, led);
  input clk;
  output [5:0] led;
  
  trafficLight DUT(.clk(clk), .light1(led[5:3]), .light2(led[2:0]));

endmodule
