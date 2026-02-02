`timescale 1ns / 1ps
module four_bit_even_parity_checker_tb;

reg A,B,C,P; 
wire PEC;

integer i;

initial begin
for (i=0; i<16; i=i+1) begin
{A,B,C,P} = i;
#10;
end
end

four_bit_even_parity_checker UUT(.A(A), .B(B), .C(C), .P(P), .PEC(PEC));

endmodule
