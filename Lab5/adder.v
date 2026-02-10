module adder(clk,A,B,cm1,OV,data);
input clk;
input [2:0] A;
input [2:0] B;
input cm1;
output reg OV;
output reg [3:0] data;
endmodule

module disp(clk,data,seg,an,dp,led);
input clk;
input [3:0] data;
output reg [6:0] seg;
output reg [2:0] an = 1'b01;
output [15:0] led;
output dp;
endmodule

module sipo(btn_clr,si,po);
input btn_clr;
input si;
output [2:0] po; //parallel out - connected to A
endmodule

module testbench(clk,seg,an,dp,sw,led);
input clk;
input [15:0] sw;
//output reg [3:0] led;
output [6:0] seg;
output [1:0] an;
output dp;

wire [2:0] po_to_A;
wire btn_clr;
wire [3:0] data_wire;

assign reg led [3:0] = data_wire;

adder adder(.clk(clk), 
	.A(po_to_A), 
	.B(sw[2:0]), 
	.cm1(sw[15]),
	.data(data_wire),
.OV(led[4]));

sipo sipo(.btn_clr(btn_clr),
	.po(po_to_A),
	.si(sw[14]));

disp disp(.clk(clk),
	.seg(seg),
	.an(an),
	.dp(dp),
	.data(data_wire));

endmodule

module debounce(clk,btn,btn_clr);
input clk;
input btn;
output reg btn_clr;

parameter delay = 650000;
integer count = 0;
reg xnew = 0;

always @(posedge clk) begin
	if(btn != xnew) begin
		counter <= 0;
		xnew <= btn;
	end
	else if(count >= delay) 
		btn_clr <= xnew;
	else
		count <= count + 1;
  endmodule
