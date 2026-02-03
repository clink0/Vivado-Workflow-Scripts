module trafficLight(clk, light1, light2);
input clk;
output [2:0] light1;
output [2:0] light2;
reg [2:0] in = 3'b0;
reg [31:0] cnt;
parameter cntmax = 32'd100000000;

assign light1[2] = (~in[2] & in[1] & in[0]) | (in[2] & ~in[1] & ~in[0]) ;  
assign light1[1] = (in[2] & ~in[1] & in[0]);  
assign light1[0] = (~in[2] & ~in[1]) | (~in[2] & ~in[0]) | (in[2] & in[1]);

assign light2[2] = (~in[2] & ~in[1] & ~in[0]);  
assign light2[1] = (~in[2] & ~in[1] & in[0]);  
assign light2[0] = in[2] | in[1];

always @(posedge clk)
begin
  if(cnt == cntmax & in != 3'b110)
    begin
      cnt <= 0;
      in <= in + 1;
    end
  else if (cnt == cntmax & in == 3'b110)
    begin
      cnt <= 0;
      in <= 0;
    end
  else
    cnt <= cnt + 1;
end
endmodule
