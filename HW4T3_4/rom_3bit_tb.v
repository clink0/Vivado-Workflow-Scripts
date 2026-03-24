module rom_tb;
reg [5:0] address;
reg read_en, ce;
wire [2:0] data;
integer i;
initial begin
  address = 0;
  read_en = 0;
  ce      = 0;
  #10 $monitor ("address = %h, data = %b, read_en = %b, ce = %b", address, data, read_en, ce);
  for (i = 0; i < 6; i = i + 1)begin
    #5 address = i;
    read_en = 1;
    ce = 1;
    #5 read_en = 0;
    ce = 0;
    address = 0;
  end
end
rom U(
.address(address) , // Address input
.data(data)       , // Data output
.read_en(read_en) , // Read Enable
.ce(ce)             // Chip Enable
);
endmodule
