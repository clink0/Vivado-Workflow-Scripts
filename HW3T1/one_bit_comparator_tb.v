`timescale 1ns / 1ps
module one_bit_comparator_tb;

reg x,y;  
wire g,e,l;

initial
begin
x=0; y=0;
#10;
x=0; y=1;
#10;
x=1; y=0;
#10;
x=1; y=1;
#10;
end

one_bit_comparator UUT(.x(x), .y(y), .g(g), .e(e), .l(l));

endmodule
