module four_bit_even_parity_checker(PEC,A,B,C,P);

input A,B,C,P;
output PEC;

// Dataflow modeling
assign PEC = (A^B)^(C^P);

endmodule
