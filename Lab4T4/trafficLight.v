module trafficLight(clk, light);
input clk;
output reg [5:0] light;

reg [2:0] state = 3'b000;
reg [31:0] cnt;
parameter cntmax = 32'd100000000;
parameter cnt_rush = 32'd200000000;

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
	      light <= 6'b001100;
      end
    end
  3'b001:
    begin
      if(cnt == cntmax)
      begin
	      cnt <= 0;
	      state <= state + 1;
      end
      else
      begin
	      cnt <= cnt + 1;
	      light <= 6'b001010;
      end
    end
  3'b010:
    begin
      if(cnt == cntmax)
      begin
	      cnt <= 0;
	      state <= state + 1;
      end
      else
      begin
	      cnt <= cnt + 1;
	      light <= 6'b001001;
      end
    end
  3'b011:
    begin
      if(cnt >= cnt_rush)
      begin
	      cnt <= 0;
	      state <= state + 1;
      end
      else
      begin
	      cnt <= cnt + 1;
	      light <= 6'b100001;
      end
    end
  3'b100:
    begin
      if(cnt == cntmax)
      begin
	      cnt <= 0;
	      state <= state + 1;
      end
      else
      begin
	      cnt <= cnt + 1;
	      light <= 6'b010001;
      end
    end
  3'b101:
    begin
      if(cnt == cntmax)
      begin
	      cnt <= 0;
	      state <= 3'b000;
      end
      else
      begin
	      cnt <= cnt + 1;
	      light <= 6'b001001;
      end
    end
  endcase
end
endmodule
