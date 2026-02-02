module carpark(c,s);

input [8:0] s;
output reg [3:0] c;

always @(s)
c = s[8]+s[7]+s[6]+s[5]+s[4]+s[3]+s[2]+s[1]+s[0];

endmodule
