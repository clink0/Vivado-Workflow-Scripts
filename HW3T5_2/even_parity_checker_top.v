module even_parity_checker_top(led,sw);

input [3:0] sw;
output [0:0] led;

four_bit_even_parity_checker UUT(.PEC(led[0]), .A(sw[0]), .B(sw[1]), .C(sw[2]), .P(sw[3]));

endmodule
