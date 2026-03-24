module btnCounter(
    clk,
    btn_clr,
    digit
);
  input clk;
  input btn_clr;
  output reg [3:0] digit = 4'd0;
  reg btn_prev = 0;

  always @(posedge clk)
  begin
    btn_prev <= btn_clr;
    if (btn_clr == 1'b1 && btn_prev == 1'b0)
    begin
      if (digit == 4'd9)
        digit <= 4'd0;
      else
        digit <= digit + 1'b1;
    end
  end
endmodule
