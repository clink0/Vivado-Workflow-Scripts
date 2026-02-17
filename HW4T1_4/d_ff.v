module D_flip_flop(d,clk,clr,q,qn);

input d,clk,clr;

output reg q;
output reg qn;

always @ (posedge clk, negedge clr)
if (clr == 0) begin
  q <= 0;
  qn <= 1;
  end
  else begin
  q <= d;
  qn <= ~d;
  end
endmodule
