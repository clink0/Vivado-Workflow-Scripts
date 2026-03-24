module T_flip_flop(t,clk,clr,q,qn);

input t,clk,clr;
output reg q;
output reg qn;

always @ (posedge clk, negedge clr)
if (clr == 0) begin
  q <= 0;
  qn <= 1;
  end
  else begin
  q <= q ^ t;
  qn<= ~(q ^ t);
end
endmodule
