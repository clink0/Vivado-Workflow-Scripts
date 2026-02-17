module SR_latch(s,r,q,qn);

// Port definitions
input s,r;

// for behavioral modeling
output reg q;
output reg qn;

// Behavioral modeling
always @ (s or r)
if (s) {q,qn} <= 2'b10;
else if (r) {q,qn} <= 2'b01;

endmodule

