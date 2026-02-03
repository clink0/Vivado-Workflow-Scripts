module three_bit_even_parity_generator(p,A,B,C);

input A,B,C;
output p;

// for structural modeling
wire w1;

// structural modeling
xor g1(w1,A,B);
xor g2(p,w1,C);

// Dataflow modeling
assign p=A^B^C;

endmodule
