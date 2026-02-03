`timescale 1ns / 1ps
module N_bit_comparator_tb;

parameter N = 4;

reg [N-1:0] x, y; 
wire [2:0] comp;

integer i;

initial begin
x=4'h0; y=4'h0;
#10;
x=4'h5; y=4'h3;
#10;
x=4'h3; y=4'h5;
#10;
x=4'hA; y=4'hA;
#10;
x=4'hF; y=4'h0;
#10;
x=4'h0; y=4'hF;
#10;
x=4'h7; y=4'h8;
#10;
x=4'hB; y=4'h6;
#10;
end

N_bit_comparator UUT(.x(x), .y(y), .comp(comp));

endmodule
