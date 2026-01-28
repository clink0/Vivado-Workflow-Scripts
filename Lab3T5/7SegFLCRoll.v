module SSDispFLC(clk, seg, dp, an);
input clk;
output dp;
output reg [6:0] seg;
output reg [3:0] an;

reg [1:0] state = 2'b00;
assign dp = 1'b1;
parameter cntmax = 10'd1023;
reg [9:0] cnt = 0;

reg [25:0] timer = 0;
reg [1:0] shift = 0;

always @(posedge clk)
begin
  if (timer >= 30000000)
  begin
    timer <= 0;
    shift <= shift + 1;
  end
  else timer <= timer + 1;

  if(cnt == cntmax)
  begin
    if (state == 2'b00)
       begin
         cnt <= 0;
	 an <= 4'b1110;
	 case(shift)
           0 : seg <= 7'b1000110;
	   1 : seg <= 7'b1111111;
	   2 : seg <= 7'b0001110;
	   3 : seg <= 7'b1000111;
         endcase
	 state <= state + 1;
       end

    else if (state == 2'b01)
       begin
         cnt <= 0;
	 an <= 4'b1101;
	 case(shift)
           0 : seg <= 7'b1000111;
           1 : seg <= 7'b1000110;
	   2 : seg <= 7'b1111111;
	   3 : seg <= 7'b0001110;
  	   endcase
	 state <= state + 1;
       end

    else if (state == 2'b10)
       begin
         cnt <= 0;
	 an <= 4'b1011;
	 case(shift)
           0 : seg <= 7'b0001110;
	   1 : seg <= 7'b1000111;
	   2 : seg <= 7'b1000110;
	   3 : seg <= 7'b1111111;
	 endcase
	 state <= state + 1;
       end

     else if (state == 2'b11)
       begin
         cnt <= 0;
	 an <= 4'b0111;
	 case(shift)
           0 : seg <= 7'b1111111;  
	   1 : seg <= 7'b0001110;
	   2 : seg <= 7'b1000111;
	   3 : seg <= 7'b1000110;
         endcase
	 state <= 2'b00;
       end

  end
  else cnt <= cnt + 1;
end
endmodule
