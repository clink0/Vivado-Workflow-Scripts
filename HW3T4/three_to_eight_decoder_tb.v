`timescale 1ns / 1ps
module three_to_eight_decoder_tb;

reg [2:0] x; 
wire [7:0] y;

integer i;

initial begin
for (i=0; i<8; i=i+1) begin
x = i;
#10;
end
end

three_to_eight_decoder UUT(.x(x), .y(y));

endmodule
