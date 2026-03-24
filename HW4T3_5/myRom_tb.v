`timescale 1ns / 1ps
module myRom_tb;

reg [15:0] address;
reg clk;
wire [7:0] data;
integer i;

initial begin
  clk = 0;
  address = 0;
  #10 $monitor ("address = %h, data = %h, clk = %b", address, data, clk);
  for (i = 0; i < 61440; i = i + 10)begin //the maximum loop number in Vivado is 64 so use i+10 each loop
    #4 address = i;
    #1 clk = ~clk;
    #4 address = 0;
  end
end

myRom U(
.addra(address) , // Address input
.douta(data)    , // Data output
.clka(clk)
);
endmodule
