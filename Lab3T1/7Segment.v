module SSDisp(clk, an, seg, dp);
input clk;
output [3:0] an;
output reg [6:0] seg;
output dp;

reg[3:0] digit = 4'b0;

assign dp = 1'b1;
assign an[3:0] = 4'b0000;

always @ (posedge clk)
begin
  case(digit)
  
  4'b0000 : seg <= 7'b1000000;
  4'b0001 : seg <= 7'b0000110;
  
  endcase

end
endmodule 
