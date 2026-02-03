module carpark_top(led,sw,seg,an);

input [8:0] sw;
output [3:0] led;
output [6:0] seg;
output [3:0] an;

assign an = 4'b1110;

carpark park1(.c(led), .s(sw));
decoder_7seg ss(.in1(led), .out1(seg));

endmodule
