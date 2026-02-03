module trafficLight(clk, light1, light2);
input clk;
output reg [5:0] G1Y1R1G2Y2R2;
reg [2:0] state = 3'b000;
reg [31:0] cnt;
parameter cntmax = 32'd100000000;

always @(posedge clk)
begin
case(state)
  3'b000:
    begin
      if(cnt == cntmax)
      begin
	      cnt <= 0;
	      state <= state + 1;
      end
      else
      begin
	      cnt <= cnt + 1;
	      G1Y1R1G2Y2R2 <= 6'b001100;
      end
    end
  3'b000:
    begin
      if(cnt == cntmax)
      begin
	      cnt <= 0;
	      state <= state + 1;
      end
      else
      begin
	      cnt <= cnt + 1;
	      G1Y1R1G2Y2R2 <= 6'b001100;
      end
    end
  3'b000:
    begin
      if(cnt == cntmax)
      begin
	      cnt <= 0;
	      state <= state + 1;
      end
      else
      begin
	      cnt <= cnt + 1;
	      G1Y1R1G2Y2R2 <= 6'b001100;
      end
    end
  3'b000:
    begin
      if(cnt == cntmax)
      begin
	      cnt <= 0;
	      state <= state + 1;
      end
      else
      begin
	      cnt <= cnt + 1;
	      G1Y1R1G2Y2R2 <= 6'b001100;
      end
    end
  3'b000:
    begin
      if(cnt == cntmax)
      begin
	      cnt <= 0;
	      state <= state + 1;
      end
      else
      begin
	      cnt <= cnt + 1;
	      G1Y1R1G2Y2R2 <= 6'b001100;
      end
    end
  3'b000:
    begin
      if(cnt == cntmax)
      begin
	      cnt <= 0;
	      state <= state + 1;
      end
      else
      begin
	      cnt <= cnt + 1;
	      G1Y1R1G2Y2R2 <= 6'b001100;
      end
    end



end
endmodule
