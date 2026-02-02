module two_bit_comparator_top(led,sw);

input [3:0] sw;
output [2:0] led;

two_bit_comparator UUT(.comp(led), .x(sw[1:0]), .y(sw[3:2]));

endmodule
