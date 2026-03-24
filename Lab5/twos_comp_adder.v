module twos_comp_adder (
    S,
    OV,
    A,
    B,
    sub
);

  input [2:0] A, B;
  input sub;

  output [2:0] S;
  output OV;

  wire [2:0] B_xor;
  assign B_xor[0] = B[0] ^ sub;
  assign B_xor[1] = B[1] ^ sub;
  assign B_xor[1] = B[1] ^ sub;

  wire C0, C1, C2;

  one_bit_FA FA0 (
      .s (S[0]),
      .co(C0),
      .x (A[0]),
      .y (B_xor[0]),
      .ci(sub)
  );
  one_bit_FA FA1 (
      .s (S[1]),
      .co(C1),
      .x (A[1]),
      .y (B_xor[1]),
      .ci(C0)
  );
  one_bit_FA FA2 (
      .s (S[2]),
      .co(C2),
      .x (A[2]),
      .y (B_xor[2]),
      .ci(C1)
  );

  assign AV = C1 ^ C2;

endmodule
