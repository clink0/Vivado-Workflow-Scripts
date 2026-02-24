module btnCounter_top(
    clk,
    btnC,
    seg,
    an,
    dp
);
  input clk;
  input btnC;
  output [6:0] seg;
  output [3:0] an;
  output dp;

  wire btnC_clr;
  wire [3:0] digit;

  debounce debounce_UT(.clk(clk), .btn(btnC), .btn_clr(btnC_clr));
  btnCounter counter_UT(.clk(clk), .btn_clr(btnC_clr), .digit(digit));
  display display_UT(.clk(clk), .data(digit), .seg(seg), .an(an), .dp(dp));

endmodule
