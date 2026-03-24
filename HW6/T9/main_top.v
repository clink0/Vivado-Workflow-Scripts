module main_top(
    clk,
    sw,
    led
);
  input clk;
  input  [7:0] sw;
  output [7:0] led;

  reg  [7:0] led_reg = 8'b0;

  wire [11:0] address;
  wire [17:0] instruction;
  wire        bram_enable;
  wire [7:0]  port_id;
  wire [7:0]  out_port;
  wire [7:0]  in_port;
  wire        write_strobe;
  wire        k_write_strobe;
  wire        read_strobe;
  wire        interrupt     = 1'b0;
  wire        interrupt_ack;
  wire        kcpsm6_sleep  = 1'b0;
  wire        kcpsm6_reset;

  assign in_port = sw;
  assign led     = led_reg;

  kcpsm6 #(
      .interrupt_vector        (12'h3FF),
      .scratch_pad_memory_size (64),
      .hwbuild                 (8'h00))
  processor (
      .address        (address),
      .instruction    (instruction),
      .bram_enable    (bram_enable),
      .port_id        (port_id),
      .write_strobe   (write_strobe),
      .k_write_strobe (k_write_strobe),
      .out_port       (out_port),
      .read_strobe    (read_strobe),
      .in_port        (in_port),
      .interrupt      (interrupt),
      .interrupt_ack  (interrupt_ack),
      .reset          (kcpsm6_reset),
      .sleep          (kcpsm6_sleep),
      .clk            (clk)
  );

  prog #(
      .C_FAMILY             ("7S"),
      .C_RAM_SIZE_KWORDS    (2),
      .C_JTAG_LOADER_ENABLE (1))
  program_rom (
      .rdl         (kcpsm6_reset),
      .enable      (bram_enable),
      .address     (address),
      .instruction (instruction),
      .clk         (clk)
  );

  always @(posedge clk)
    if (write_strobe == 1'b1)
      led_reg <= out_port;

endmodule
