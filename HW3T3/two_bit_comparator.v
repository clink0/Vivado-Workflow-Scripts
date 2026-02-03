module two_bit_comparator(comp,x,y);

input [1:0] x, y;
output reg [2:0] comp;

always @ (x or y)
if (x > y) comp = 3'b100;
else if (x == y) comp = 3'b010;
else if (x < y) comp = 3'b001;
else comp = 3'b111;

endmodule
