// Scan code to ASCII converter
// Takes PS/2 scan code [7:0], outputs ASCII character
// Only handles standard printable keys (no shift/caps for simplicity)
module scancode_to_ascii(scancode, ascii);

input [7:0] scancode;
output reg [7:0] ascii;

always @(*)
begin
  case (scancode)
    // Numbers row
    8'h16: ascii = 8'h31; // 1
    8'h1E: ascii = 8'h32; // 2
    8'h26: ascii = 8'h33; // 3
    8'h25: ascii = 8'h34; // 4
    8'h2E: ascii = 8'h35; // 5
    8'h36: ascii = 8'h36; // 6
    8'h3D: ascii = 8'h37; // 7
    8'h3E: ascii = 8'h38; // 8
    8'h46: ascii = 8'h39; // 9
    8'h45: ascii = 8'h30; // 0
    // Top row letters
    8'h15: ascii = 8'h71; // q
    8'h1D: ascii = 8'h77; // w
    8'h24: ascii = 8'h65; // e
    8'h2D: ascii = 8'h72; // r
    8'h2C: ascii = 8'h74; // t
    8'h35: ascii = 8'h79; // y
    8'h3C: ascii = 8'h75; // u
    8'h43: ascii = 8'h69; // i
    8'h44: ascii = 8'h6F; // o
    8'h4D: ascii = 8'h70; // p
    // Home row letters
    8'h1C: ascii = 8'h61; // a
    8'h1B: ascii = 8'h73; // s
    8'h23: ascii = 8'h64; // d
    8'h2B: ascii = 8'h66; // f
    8'h34: ascii = 8'h67; // g
    8'h33: ascii = 8'h68; // h
    8'h3B: ascii = 8'h6A; // j
    8'h42: ascii = 8'h6B; // k
    8'h4B: ascii = 8'h6C; // l
    // Bottom row letters
    8'h1A: ascii = 8'h7A; // z
    8'h22: ascii = 8'h78; // x
    8'h21: ascii = 8'h63; // c
    8'h2A: ascii = 8'h76; // v
    8'h32: ascii = 8'h62; // b
    8'h31: ascii = 8'h6E; // n
    8'h3A: ascii = 8'h6D; // m
    // Space, Enter, Backspace
    8'h29: ascii = 8'h20; // space
    8'h5A: ascii = 8'h0D; // Enter (CR)
    8'h66: ascii = 8'h08; // Backspace
    // Default: send '?' for unknown scan codes
    default: ascii = 8'h3F; // ?
  endcase
end

endmodule
