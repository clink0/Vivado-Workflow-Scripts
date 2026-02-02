module one_bit_comparator(g,e,l,x,y);

// Port definitions
input x,y;
// for structural and functional modeling
output g,e,l;

// for structural modeling
wire o1,o2,o3;

// Structural modeling
not g1(o1,y);
and g2(g,o1,x);
xor g3(o2,x,y);
not g4(e,o2);
not g5(o3,x);
and g6(l,o3,y);

// Dataflow modeling
assign g = x & ~y;
assign e = ~(x ^ y);
assign l = ~x & y;

endmodule
