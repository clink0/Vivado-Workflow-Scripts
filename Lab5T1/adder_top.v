module adder_top (
    clk,
    sw,
    led
);
  input clk;
  input [15:0] sw;
  output [15:0] led;

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

  assign led[3:0] = result_data;
  assign led[15]  = overflow;

endmodule
