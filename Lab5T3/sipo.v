module sipo (
    btn_clr,
    si,
    po
);
  input btn_clr;
  input si;
  output reg [2:0] po;

  always @(posedge btn_clr) begin
    po <= {po[1:0], si};
  end
endmodule
