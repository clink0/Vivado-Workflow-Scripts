module adder_top (
    clk,
    sw,
    seg,
    an,
    dp
);
  input clk;
  input [15:0] sw;
  output [6:0] seg;
  output [1:0] an;
  output dp;

  wire [3:0] result_data;
  wire overflow;

  adder U1 (
      .clk(clk),
      .cm1(sw[15]),
      .A(sw[2:0]),
      .B(sw[5:3]),
      .data(result_data),
      .OV(overflow)
  );

  disp U2 (
      .clk (clk),
      .dp  (dp),
      .seg (seg),
      .an  (an),
      .data(result_data)
  );

endmodule
