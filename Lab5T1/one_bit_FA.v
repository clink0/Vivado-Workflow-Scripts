module one_bit_FA(s, co, x, y, ci);

input x, y, ci;
output s, co;

assign co = (x&y) | (ci&(x^y));
assign s = x^y^ci;

endmodule
