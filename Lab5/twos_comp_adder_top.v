module twos_comp_adder_top(sw, led);

input [6:0] sw;
output [3:0] led;

twos_comp_adder(.S(led[2:0]), .OV(led[3]), .A(sw[2:0]), .B(sw[5:3]), .sub(sw[6]));

endmodule
