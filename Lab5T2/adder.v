module adder(clk, A, B, cm1, OV, data);

input clk, cm1;
input [2:0] A, B;

output reg OV;
output reg [3:0] data;

endmodule

module disp(clk, data, seg, an, dp);

input clk;
input [3:0] data;
output [6:0] seg;
output [1:0] an;

endmodule

module testbench(clk, seg, an, dp, sw);

input clk;
input [15:0] sw;
output [6:0] seg;
output [1:0] an;
output dp;
wire [2:0] po_to_A;
wire btn_clr;
wire [3:0] data_wire;

adder adder(.clk(clk), .A(po_to_A), .B(sw[2:0]), .cm1(sw[3]), .data(led[3:0]), .OV(led[4]));

sipo sipo(.btn_clr(btn_clr), .si(sw[14]), .po(po_to_A));

disp disp(.clk(clk), .seg(seg), .an(an), .dp(dp), .data(led[3:0]));

endmodule

module sipo(btn_clr, si, po);
input btn_clr, si;
output [2:0] po;
endmodule


module debounce(clk, btn, btn_clr);
input clk;
input btn;
output reg btn_clr;

parameter delay = 650000;
integer count = 0;
reg xnew = 0;

always @ (posedge clk)
begin
  if (btn != xnew)
  begin
    count <= 0;
    xnew <= btn;
  end
  else if (count == delay)
    btn_clr <= xnew;
  else
    count <= count + 1;
end
endmodule
