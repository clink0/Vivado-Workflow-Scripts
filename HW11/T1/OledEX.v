`timescale 1ns / 1ps
// OledEX — character display driver for SSD1306 (128x32, page addressing mode)
// Holds a 4-row x 16-col ASCII character buffer (current_screen).
// Each character is rendered from charLib (8x8 font ROM, column-major, bit0=top).
// Continuously refreshes the display once EN is asserted.
module OledEX(
    input  wire        CLK,
    input  wire        RST,
    input  wire        EN,         // from top controller (high after init)
    input  wire        DONE_SPI,
    input  wire [7:0]  charlib_dout,
    output wire [10:0] charlib_addr, // {char_code[7:0], col[2:0]}
    output reg         SND,
    output reg  [7:0]  DATA,
    output reg         DC,
    output reg         FIN          // 1-cycle pulse per full screen refresh
);
    // ── Character buffer (4 pages x 16 chars, each an ASCII code) ────────
    reg [7:0] current_screen [0:3][0:15];

    initial begin
        // Row 0: "HELLO  BASYS3!  "
        current_screen[0][0]=8'h48; current_screen[0][1]=8'h45;
        current_screen[0][2]=8'h4C; current_screen[0][3]=8'h4C;
        current_screen[0][4]=8'h4F; current_screen[0][5]=8'h20;
        current_screen[0][6]=8'h20; current_screen[0][7]=8'h42;
        current_screen[0][8]=8'h41; current_screen[0][9]=8'h53;
        current_screen[0][10]=8'h59;current_screen[0][11]=8'h53;
        current_screen[0][12]=8'h33;current_screen[0][13]=8'h21;
        current_screen[0][14]=8'h20;current_screen[0][15]=8'h20;

        // Row 1: "SSD1306  128x32 "
        current_screen[1][0]=8'h53; current_screen[1][1]=8'h53;
        current_screen[1][2]=8'h44; current_screen[1][3]=8'h31;
        current_screen[1][4]=8'h33; current_screen[1][5]=8'h30;
        current_screen[1][6]=8'h36; current_screen[1][7]=8'h20;
        current_screen[1][8]=8'h20; current_screen[1][9]=8'h31;
        current_screen[1][10]=8'h32;current_screen[1][11]=8'h38;
        current_screen[1][12]=8'h78;current_screen[1][13]=8'h33;
        current_screen[1][14]=8'h32;current_screen[1][15]=8'h20;

        // Row 2: " PMOD OLED DEMO "
        current_screen[2][0]=8'h20; current_screen[2][1]=8'h50;
        current_screen[2][2]=8'h4D; current_screen[2][3]=8'h4F;
        current_screen[2][4]=8'h44; current_screen[2][5]=8'h20;
        current_screen[2][6]=8'h4F; current_screen[2][7]=8'h4C;
        current_screen[2][8]=8'h45; current_screen[2][9]=8'h44;
        current_screen[2][10]=8'h20;current_screen[2][11]=8'h44;
        current_screen[2][12]=8'h45;current_screen[2][13]=8'h4D;
        current_screen[2][14]=8'h4F;current_screen[2][15]=8'h20;

        // Row 3: "  CE433  2026   "
        current_screen[3][0]=8'h20; current_screen[3][1]=8'h20;
        current_screen[3][2]=8'h43; current_screen[3][3]=8'h45;
        current_screen[3][4]=8'h34; current_screen[3][5]=8'h33;
        current_screen[3][6]=8'h33; current_screen[3][7]=8'h20;
        current_screen[3][8]=8'h20; current_screen[3][9]=8'h32;
        current_screen[3][10]=8'h30;current_screen[3][11]=8'h32;
        current_screen[3][12]=8'h36;current_screen[3][13]=8'h20;
        current_screen[3][14]=8'h20;current_screen[3][15]=8'h20;
    end

    // ── Counters ──────────────────────────────────────────────────────────
    reg [1:0] page_cnt;     // 0..3
    reg [3:0] char_cnt;     // 0..15
    reg [2:0] col_cnt;      // 0..7

    // charLib address is driven combinationally so the ROM output
    // is ready after 1 registered clock cycle (WAIT_ROM state).
    assign charlib_addr = {current_screen[page_cnt][char_cnt], col_cnt};

    // ── FSM ───────────────────────────────────────────────────────────────
    reg [3:0] state;
    localparam IDLE      = 4'd0,
               SET_PAGE  = 4'd1,
               WP_SPI    = 4'd2,
               SET_COL_L = 4'd3,
               WCL_SPI   = 4'd4,
               SET_COL_H = 4'd5,
               WCH_SPI   = 4'd6,
               WAIT_ROM  = 4'd7,
               SEND_DATA = 4'd8,
               WD_SPI    = 4'd9;

    always @(posedge CLK) begin
        SND <= 0; FIN <= 0;
        if (RST || !EN) begin
            state    <= IDLE;
            page_cnt <= 0; char_cnt <= 0; col_cnt <= 0;
        end else case (state)
            IDLE: begin
                page_cnt <= 0; char_cnt <= 0; col_cnt <= 0;
                state <= SET_PAGE;
            end

            // ── Set page address ──────────────────────────────────────────
            SET_PAGE: begin
                DC <= 0; DATA <= 8'hB0 | {6'b0, page_cnt};
                SND <= 1; state <= WP_SPI;
            end
            WP_SPI: begin if (DONE_SPI) state <= SET_COL_L; end

            // ── Set column start = 0 (low nibble then high nibble) ────────
            SET_COL_L: begin
                DC <= 0; DATA <= 8'h00; SND <= 1; state <= WCL_SPI;
            end
            WCL_SPI: begin if (DONE_SPI) state <= SET_COL_H; end

            SET_COL_H: begin
                DC <= 0; DATA <= 8'h10; SND <= 1; state <= WCH_SPI;
            end
            WCH_SPI: begin if (DONE_SPI) state <= WAIT_ROM; end

            // ── Render 128 data bytes (16 chars × 8 cols) ────────────────
            WAIT_ROM: begin
                // charlib_addr is combinational; one registered cycle
                // through the synchronous ROM gives valid dout.
                state <= SEND_DATA;
            end

            SEND_DATA: begin
                DC <= 1; DATA <= charlib_dout; SND <= 1; state <= WD_SPI;
            end

            WD_SPI: begin
                if (DONE_SPI) begin
                    // Advance column / char / page
                    if (col_cnt < 7) begin
                        col_cnt <= col_cnt + 1;
                        state   <= WAIT_ROM;
                    end else begin
                        col_cnt <= 0;
                        if (char_cnt < 15) begin
                            char_cnt <= char_cnt + 1;
                            state    <= WAIT_ROM;
                        end else begin
                            char_cnt <= 0;
                            if (page_cnt < 3) begin
                                page_cnt <= page_cnt + 1;
                                state    <= SET_PAGE;
                            end else begin
                                page_cnt <= 0;
                                FIN      <= 1;
                                state    <= IDLE;  // loop
                            end
                        end
                    end
                end
            end

            default: state <= IDLE;
        endcase
    end
endmodule
