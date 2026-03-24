module D_latch(d,c,q,qn);

input d,c;

output reg q;
output reg qn;

always @ (d or c)
if (c) {q,qn} <= {d,~d};

endmodule
