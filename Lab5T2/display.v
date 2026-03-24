module display(clk, data, seg, an, dp);
input clk;
input [3:0] data;

output reg [6:0] seg;
output reg [1:0] an = 2'b01;
output dp;

parameter cntmax == 65000;
reg [15:0] cnt;

assign dp = 1'b1;

always @ (posedge clk)
begin

  if(cnt >= cntmax)
  begin
    cnt <= 0;
    an <= {an[0], an[1]};
  end
  else 
    cnt <= cnt + 1;

end

always @ (posedge clk)
begin

  if (an == 2'b01 & data[3] == 1)
    seg <= 7'b0111111; //G to a, display a negative sign
  else if (an == 2'b01 & data[3] == 0)
    seg <= 7'b1111111;
  else
  begin
    case(data)
    1000: 7'b // -8
    1001: 7'b // -7
    1010: 7'b // -6
    1011: 7'b // -5
    1100: 7'b // -4
    1101: 7'b // -3
    1110: 7'b // -2
    1111: 7'b1001111 // -1
    0000: 7'b // 0
    0001: 7'b // 1
    0010: 7'b // 2
    0011: 7'b // 3
    0100: 7'b // 4
    0101: 7'b // 5
    0110: 7'b // 6
    0111: 7'b // 7
    endcase
  end
end
endmodule
