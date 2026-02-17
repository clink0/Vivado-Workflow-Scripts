module JK_flip_flop(j,k,clr,clk,q,qn);

input j,k,clr,clk;
output reg q;
output reg qn;

always @ (posedge clk, negedge clr)
if (clr == 0)
begin
q <= 0;
qn<= 1;
end
else
case({j,k})
  2'b01 : begin q<=1'b0; qn<=1'b1;end
  2'b10 : begin q<=1'b1; qn<=1'b0;end
  2'b11 : begin q<=qn; qn<=q;end
endcase

endmodule
