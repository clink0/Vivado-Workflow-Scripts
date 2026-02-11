module adder_top (
    clk,
    sw,
    btnC,
    seg,
    an,
    dp,
    led
);
  input clk;
  input [15:0] sw;
  input btnC;
  output [6:0] seg;
  output [1:0] an;
  output dp;
  output [15:0] led;

  wire [2:0] po_to_A;
  wire btn_clr;
  wire [3:0] data_wire;

  assign led[3:0]  = data_wire;
  assign led[15:4] = 0;

  debounce U_Debounce (
      .clk(clk),
      .btn(btnC),
      .btn_clr(btn_clr)
  );

  sipo U_Sipo (
      .btn_clr(btn_clr),
      .po(po_to_A),
      .si(sw[14])
  );

  adder U_Adder (
      .clk(clk),
      .A(po_to_A),
      .B(sw[2:0]),
      .cm1(sw[15]),
      .data(data_wire),
      .OV(led[4])
  );

  display U_Display (
      .clk (clk),
      .seg (seg),
      .an  (an),
      .dp  (dp),
      .data(data_wire)
  );

endmodule
