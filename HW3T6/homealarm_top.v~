module home_alarm_top(sw,led,seg,an);

input [4:0] sw;
output [0:0] led;
output [6:0] seg;
output [3:0] an;

wire [3:0] act;

assign an = 4'b1110;

assign act = {sw[4],1'b0,sw[4],1'b0};

7seg ss(.in1(act), .out1(seg));
homealarm HA(.a(led), .s(sw[3:0]), .m(sw[4]));

endmodule
