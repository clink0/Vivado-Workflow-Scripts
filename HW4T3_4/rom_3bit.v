`timescale 1ns / 1ps
module rom (
address , // Address input
data    , // Data output
read_en , // Read Enable
ce        // Chip Enable
);

input [5:0] address;
output [2:0] data;
input        read_en;
input        ce;
reg [2:0]    mem [0:5] ;
//integer file_pointer;
assign data = (ce && read_en) ? mem[address] : 3'b0;
//integer i;
initial begin
  $readmemb("memory_3bit.mem",mem);
end
endmodule
