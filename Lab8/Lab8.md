# Lab 8
### The square problem with pushbuttons and seven segment displays (2-week lab)

## 1. Get started
First download the listings from the textbook which contains the top module, the assembly code, the display module and the debounce module.
Then download the kcpsmó design files.
Put all these files together in one directory. Rename the long file names of the listings.
In the top module, there are a few things to change:

```verilog
// Listing 17.2
module pico_btn
(
 input wire clk, reset,
 input wire [7:0] sw,
 input wire [1:0] btn,
 output wire [3:0] an,
 output wire [7:0] sseg
);

// signal declaration
// KCPSM3/ROM signals
wire [9:0] address;
wire [17:0] instruction;
wire [7:0] port_id, out_port;
reg [7:0] in_port;

// I/O port signals
// output enable
reg [3:0] en_d;

wire write_strobe, read_strobe;
// refer to the template
// four-digit seven-segment led display
reg [7:0] ds3_reg, ds2_reg, ds1_reg, ds0_reg;

// two pushbuttons
reg btnc_flag_reg, btns_flag_reg;
wire btnc_flag_next, btns_flag_next;
wire set_btnc_flag, set_btns_flag, clr_btn_flag;

//body
// ====
// I/O modules
// =====
// ===================
// ==
disp_mux disp_unit
(.clk(clk), reses (reset),
 in3(ds3_reg), in2 (ds2_reg), inl(ds1_reg),
 ino(ds0_reg), an(an),
 sseg(sseg));

debounce btnc_unit
(.clk(clk), reset(reset), sw(btn[0]),
 db_level(), db_tick(set_btnc_flag));
debounce btns_unit
(.clk(clk), reset (reset), sw(btn[1]),
 db_level(), db_tick (set_btns_flag));

// KCPSM and ROM instantiation
//
kcpsm3 proc_unit
(.clk(clk), reset (1'b0), address (address),
 instruction (instruction), port_id(port_id),
 .write_strobe (write_strobe), out_port(out_port),
 .read_strobe (read_strobe), in_port(in_port),
 .interrupt (1'b0),
 interrupt_ack());

btn_rom rom_unit
(.clk(clk), address (address),
 instruction (instruction));
// refer to the template
```

Here is the ones I used for kcpsmó and the rom.
you can use the following instantiations

```verilog
// KCPSM and ROM instantiation
//
kcpsm6 #(
 .interrupt_vector          (12'h3FF),
 .scratch_pad_memory_size   (64),
 .hwbuild                   (8'h00))
processor (
 .address        (address),
 .instruction    (instruction),
 .bram_enable    (bram_enable),
 .port_id        (port_id),
 .write_strobe   (write_strobe),
 .k_write_strobe (k_write_strobe),
 .out_port       (out_port),
 .read_strobe    (read_strobe),
 .in_port        (in_port), // make this change
 .interrupt      (1'b0), // make this change
 .interrupt_ack  (interrupt_ack),
 .reset          (rdl), // make this change
 .sleep          (1'b0), // make this change
 .clk            (clk));
//Family 'S6' or 'V6'
//Program size '1', '2' or '4'
//Include JTAG Loader when set to '1'

btn_rom #(
 .C_FAMILY             ("7S"),
 .C_RAM_SIZE_KWORDS    (1),
 .C_JTAG_LOADER_ENABLE (1))
program_rom (
 .rdl         (rdl), // make this change
 .enable      (bram_enable),
 .address     (address),
 .instruction (instruction),
 .clk         (clk));
//Name to match your PSM file
```

In the assembly file, the orignal seg code was for Spartan 3 which was {dp, a_to_g} MSB - LSB.
You need to change it to {dp, g_to_a} MSB - LSB for Basys 3.

The following table:

```assembly
(dp,g_a) for Basys 3.
The orignal code is (dp,a_g) for Spartan)

hex_to_led:
compare data, 00
jump nz, comp_hex_1
load data,  7seg pattern  
jump hex_done
comp_hex_1:
compare data, 01
jump nz, comp_hex_2
load data,  7seg pattern 1
jump hex_done
comp_hex_2:
compare data, 02
jump nz, comp_hex_3
load data,  7seg pattern 2
jump hex_done
comp_hex_3:
compare data, 03
jump nz, comp_hex_4
load data, 7seg pattern 3
jump hex_done
comp_hex_4:
compare data, 04
jump nz, comp_hex_5
load data,  7seg pattern 4
jump hex_done
comp_hex_5:
compare data, 05
jump nz, comp_hex_6
load data, 7seg pattern 5
jump hex_done
comp_hex_6:
compare data, 06
jump nz, comp_hex_7
load data, 7seg pattern 6
jump hex_done
comp_hex_7:
compare data, 07
jump nz, comp_hex_8
load data, 7seg pattern 7
jump hex_done
comp_hex_8:
compare data, 08
jump nz, comp_hex_9
load data, 7seg pattern 8
jump hex_done
comp_hex_9:
compare data, 09
jump nz, comp_hex_a
load data,  7seg pattern 9
jump hex_done
```

Make some changes in the constraint file. The example code from the textbook uses 'sseg [7:0]' for Spartan 3 board.
In Basys 3, the 'seg' variable only has 7 bits, the 8th bit is 'dp'.
You can change the name of 'dp' to seg[7] in the constraint file.

```tcl
Basys 3 seg
#7 segment display, 0-6 is a-g
set_property PACKAGE_PIN W7 [get_ports {seg[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[0]}]
# a
set_property PACKAGE_PIN W6 [get_ports {seg[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[1]}]
# b
set_property PACKAGE_PIN U8 [get_ports {seg[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[2]}]
# c
set_property PACKAGE_PIN V8 [get_ports {seg[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[3]}]
# d
set_property PACKAGE_PIN U5 [get_ports {seg[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[4]}]
# e
set_property PACKAGE_PIN V5 [get_ports {seg[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[5]}]
# f
set_property PACKAGE_PIN U7 [get_ports {seg[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[6]}]
# g
set_property PACKAGE_PIN V7 [get_ports {seg[7]}]
# dp
set_property IOSTANDARD LVCMOS33 [get_ports {seg[7]}]
```

they were 'dp'.
The lower 3 bits of the switch controls the display options.

**Handwritten Table Transcription:**

| Display | Sw[2:0] |
|---|---|
| a | 000 |
| b | 001 |
| a^2 | 010 |
| b^2 | 011 |
| a^2+b^2 | 100 |

Here is the demonstration:
Yiyan Li
Watch on

The following table:

```assembly
mult_soft:
load s5, 00 ; clear s5
load i, 08 ; initialize loop index
mult_loop:
sra s4 ; shift lsb to carry
jump nc, shift_prod ;lsb is 0
add s5, s3 ;lsb is 1
shift_prod:
sra s5 ; shift upper byte right, carry to MSB, LSB to carry
sra s6 ; shift lower byte right, lsb of s5 to MSB of s6
sub i, 01 ; dec loop index
jump nz, mult_loop ; repeat until i=0
return
```

Explanation to the multiplication assembly code.
a_lsb is just a byte. a^2 needs two bytes and that is why it has two bytes aa_Isb and aa_msb declared.
aabb_Isb and aabb_msb are the a^2+b^2 results. There is a carryout bit for the addition of the two bytes.

```assembly
; Program operation:
; read a and b from switch
; calculate a*a + b*b
; display data on 7-seg led

; Data ram address alias

constant a_lsb, 00
constant b_lsb, 02
constant aa_lsb, 04
constant aa_msb, 05
constant bb_lsb, 06
constant bb_msb, 07
constant aabb_lsb, 08
constant aabb_msb, 09
constant aabb_cout, 0A
constant led0, 10
constant ledl, 11
constant led2, 12
constant led3, 13
```

Give alias to the following registers.

```assembly
; commonly used local variables
; reg for temporary data
; ============
; Register alias
;======

namereg s0, data
namereg s1, addr
namereg s2, i ; general-purpose loop index

; global variables
; reg for temporary mem & i/o port addr
namereg sf, switch_a_bram offset for current switch input
```

What does the 'SRA' instruction do?

* **SR0 sX:** shifts a '0' into the MSB. The Z flag will only be set if bits(6:0) are all also '0' after the shift.
* **SR1 sX:** shifts a '1' into the MSB. This means that the Z flag will be always be cleared (Z=0) by this instruction.
* **SRX sX:** replicates the existing state of the MSB. The Z flag will only be set if all 8-bits of the register are zero.
* **SRA sX:** shifts the previous state of the carry flag into the MSB at the same time that the carry flag is loaded with the LSB. The Z flag will only be set if all 8-bits of the register are zero.

These instructions all shift the contents of the specified register (sX) one bit to the right.
The least significant bit (LSB) is shifted out of the register into the carry flag (C).
The bit that is shifted into the most significant bit (MSB) is defined by the shift right instruction that is used.
The zero flag (Z) will be set only if all 8-bits of the resulting value contained in the register are zero.

A shift right has the effect of dividing a value by 2. The 'SRA' instruction enables multi-byte values contained in multiple registers to be shifted.
When 2's complement is used to represent signed values then 'SRX' implements sign extension.

**Examples**
```assembly
LOAD sB, ED
LOAD sA, 2A
SR0 sA
SRA sB
[sB,sA] = ED2A -> 4822 = 1011 1010 0010 1010
[sB,sA] = F695 = -2411 = 1111 0110 1001 0101
```

```assembly
Loop: OUTPUT sF, port
      SRX sB
```
Outputs to 'port' a simple 'walking 1' pattern as illustrated on the right hand side.
```assembly
LOAD sF, 10000000
SR0 sF
```
The process terminates when the '1' is shifted into the carry flag.
```assembly
JUMP NC, loop
SRA sA
```

2. Modify the code to show the 16-bit results on the LEDs.
You can use a LED bar on any of the SSD units as the 17th bit or use one of the decimal points as the 17th bit.

3. Modify the code to display the results in HEX form on an LCD display.

**Tasks:**
Week 1:
1. Repeat the work in Section 1. (60 points)
2. Complete the task in Section 2. (40 points)

Week 2:
3. Complete the task in Section 3. (100 points)

*(Image Transcription)*: A photograph of a Xilinx Spartan-3 Starter Board produced by Digilent. It features four seven-segment displays (labeled 8.8.8.8.), multiple switches, push buttons, and various ICs.

**References**
[1] https://www.youtube.com/watch?v=mzjUCzB9aSQ
[2] Spartan 3 board information Schematic
[3] Pong Chu's book: FPGA Prototyping by Verilog Examples - Xilinx Spartan - 3 Version
[4] The KCPSM6 manual (PDF)
[5] disp_mux
[6] debounce
