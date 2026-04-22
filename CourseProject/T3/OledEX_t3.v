`timescale 1ns / 1ps
// OledEX_t3 — OLED character driver for T3 heart-rate display.
// Same FSM as OledEX (T1) but screen row 2 cols 6-7 are driven by
// bpm_tens / bpm_units from Picoblaze instead of a static initial block.
//
// Display layout (16 chars per row):
//   Row 0: "  HEART  RATE   "
//   Row 1: "                "
//   Row 2: "  BPM:  ??  BPM "    (cols 8-9 = Picoblaze BPM digits)
//   Row 3: "                "
module OledEX_t3(
    input  wire        CLK,
    input  wire        RST,
    input  wire        EN,
    input  wire        DONE_SPI,
    input  wire [7:0]  charlib_dout,
    input  wire [7:0]  bpm_tens,     // ASCII code of BPM tens digit
    input  wire [7:0]  bpm_units,    // ASCII code of BPM units digit
    output wire [10:0] charlib_addr,
    output reg         SND,
    output reg  [7:0]  DATA,
    output reg         DC,
    output reg         FIN
);
    // ── Static character buffer ───────────────────────────────────────────
    reg [7:0] screen [0:3][0:15];

    initial begin
        // Row 0: "  HEART  RATE   "
        screen[0][0]=8'h20; screen[0][1]=8'h20;
        screen[0][2]=8'h48; screen[0][3]=8'h45;
        screen[0][4]=8'h41; screen[0][5]=8'h52;
        screen[0][6]=8'h54; screen[0][7]=8'h20;
        screen[0][8]=8'h20; screen[0][9]=8'h52;
        screen[0][10]=8'h41;screen[0][11]=8'h54;
        screen[0][12]=8'h45;screen[0][13]=8'h20;
        screen[0][14]=8'h20;screen[0][15]=8'h20;

        // Row 1: "                "
        screen[1][0]=8'h20; screen[1][1]=8'h20;
        screen[1][2]=8'h20; screen[1][3]=8'h20;
        screen[1][4]=8'h20; screen[1][5]=8'h20;
        screen[1][6]=8'h20; screen[1][7]=8'h20;
        screen[1][8]=8'h20; screen[1][9]=8'h20;
        screen[1][10]=8'h20;screen[1][11]=8'h20;
        screen[1][12]=8'h20;screen[1][13]=8'h20;
        screen[1][14]=8'h20;screen[1][15]=8'h20;

        // Row 2: "  BPM:  ??  BPM "  (cols 8-9 = dynamic BPM digits)
        screen[2][0]=8'h20; screen[2][1]=8'h20;
        screen[2][2]=8'h42; screen[2][3]=8'h50;
        screen[2][4]=8'h4D; screen[2][5]=8'h3A;
        screen[2][6]=8'h20; screen[2][7]=8'h20;
        // cols 8-9 driven by bpm_tens/bpm_units (see charlib_addr_sel below)
        screen[2][8]=8'h2D; screen[2][9]=8'h2D;  // placeholder '--'
        screen[2][10]=8'h20;screen[2][11]=8'h20;
        screen[2][12]=8'h42;screen[2][13]=8'h50;
        screen[2][14]=8'h4D;screen[2][15]=8'h20;

        // Row 3: "                "
        screen[3][0]=8'h20; screen[3][1]=8'h20;
        screen[3][2]=8'h20; screen[3][3]=8'h20;
        screen[3][4]=8'h20; screen[3][5]=8'h20;
        screen[3][6]=8'h20; screen[3][7]=8'h20;
        screen[3][8]=8'h20; screen[3][9]=8'h20;
        screen[3][10]=8'h20;screen[3][11]=8'h20;
        screen[3][12]=8'h20;screen[3][13]=8'h20;
        screen[3][14]=8'h20;screen[3][15]=8'h20;
    end

    // ── Counters ──────────────────────────────────────────────────────────
    reg [1:0] page_cnt;
    reg [3:0] char_cnt;
    reg [2:0] col_cnt;

    // Dynamic character selection: row 2, cols 8-9 come from Picoblaze
    wire [7:0] cur_char =
        (page_cnt == 2 && char_cnt == 8) ? bpm_tens  :
        (page_cnt == 2 && char_cnt == 9) ? bpm_units :
        screen[page_cnt][char_cnt];

    assign charlib_addr = {cur_char, col_cnt};

    // ── FSM (identical to OledEX in T1) ──────────────────────────────────
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
            SET_PAGE: begin
                DC <= 0; DATA <= 8'hB0 | {6'b0, page_cnt};
                SND <= 1; state <= WP_SPI;
            end
            WP_SPI:  begin if (DONE_SPI) state <= SET_COL_L; end
            SET_COL_L: begin DC<=0; DATA<=8'h00; SND<=1; state<=WCL_SPI; end
            WCL_SPI: begin if (DONE_SPI) state <= SET_COL_H; end
            SET_COL_H: begin DC<=0; DATA<=8'h10; SND<=1; state<=WCH_SPI; end
            WCH_SPI: begin if (DONE_SPI) state <= WAIT_ROM; end
            WAIT_ROM: begin state <= SEND_DATA; end
            SEND_DATA: begin DC<=1; DATA<=charlib_dout; SND<=1; state<=WD_SPI; end
            WD_SPI: begin
                if (DONE_SPI) begin
                    if (col_cnt < 7) begin
                        col_cnt <= col_cnt + 1; state <= WAIT_ROM;
                    end else begin
                        col_cnt <= 0;
                        if (char_cnt < 15) begin
                            char_cnt <= char_cnt + 1; state <= WAIT_ROM;
                        end else begin
                            char_cnt <= 0;
                            if (page_cnt < 3) begin
                                page_cnt <= page_cnt + 1; state <= SET_PAGE;
                            end else begin
                                page_cnt <= 0; FIN <= 1; state <= IDLE;
                            end
                        end
                    end
                end
            end
            default: state <= IDLE;
        endcase
    end
endmodule
