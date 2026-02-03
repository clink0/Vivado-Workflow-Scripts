module quiz(clk, sw, led);
input clk;
input [2:0] sw;
output reg [0:0] led;


always @ (posedge clk)
begin
  case(sw)
    3'b000 : led <= 1;
    3'b001 : led <= 0;
    3'b010 : led <= 0;
    3'b011 : led <= 1;
    3'b100 : led <= 0;
    3'b101 : led <= 1;
    3'b110 : led <= 1;
    3'b111 : led <= 0;
  endcase
end
endmodule
