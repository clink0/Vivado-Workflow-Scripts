`timescale 1ns / 1ps
module three_bit_even_parity_generator_tb;

reg A,B,C; 
wire p;

integer i;

initial begin
for (i=0; i<8; i=i+1) begin
{A,B,C} = i;
#10;
end
end

three_bit_even_parity_generator UUT(.A(A), .B(B), .C(C), .p(p));

endmodule
