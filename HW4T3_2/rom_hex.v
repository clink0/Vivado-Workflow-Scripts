`timescale 1ns / 1ps
module rom (
address , // Address input
data    , // Data output
read_en , // Read Enable
ce        // Chip Enable
);

input [3:0] address;
output [15:0] data;
input         read_en;
input         ce;
reg [15:0]    mem [0:3] ;
//integer file_pointer;
assign data = (ce && read_en) ? mem[address] : 15'b0;
//integer i;
initial begin
  $readmemh("memory_hex.mem",mem);
end
endmodule

