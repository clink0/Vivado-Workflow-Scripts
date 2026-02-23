`timescale 1ns / 1ps
module rom (
address , // Address input
data    , // Data output
read_en , // Read Enable
ce        // Chip Enable
);

input [15:0] address;
output [7:0] data;
input        read_en;
input        ce;
reg [7:0]    mem [0:15] ;
//integer file_pointer;
assign data = (ce && read_en) ? mem[address] : 8'b0;
//integer i;
initial begin
  $readmemh("memory_8bit.mem",mem);
end
endmodule
