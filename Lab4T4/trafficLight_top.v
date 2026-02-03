module trafficLight_top(clk, led);
  input clk;
  output [5:0] led;
  
  trafficLight DUT(.clk(clk), .light(led[5:0]));

endmodule
