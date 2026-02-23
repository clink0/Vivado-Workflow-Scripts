module LCD_driver_top(clk, JB, JA);
                   
input clk;             
output [7:0] JB;
output [7:0] JA;
parameter clk_param = 16000000; // 16000000/100000000 = 0.16 s per character
   
reg [7:0] data [15:0];
reg [7:0] data_in;
integer counter = 0;
reg [3:0] index = 0;
reg wr_en = 0;
reg done = 0; // flag: all 16 chars sent once, stop cycling

LCD_driver lcd1(.clk(clk), .wr_en(wr_en), .data_in(data_in),
    .data_out(JA), .en(JB[0]), .rs(JB[2]));

// Steady text: "HELLO WORLD!    "
initial
begin
    data[0]  = "H";
    data[1]  = "E";
    data[2]  = "L";
    data[3]  = "L";
    data[4]  = "O";
    data[5]  = " ";
    data[6]  = "W";
    data[7]  = "O";
    data[8]  = "R";
    data[9]  = "L";
    data[10] = "D";
    data[11] = "!";
    data[12] = " ";
    data[13] = " ";
    data[14] = " ";
    data[15] = " ";
end

always @(posedge clk)
begin
    if (!done)
    begin
        if (counter >= clk_param)
        begin
            counter <= 0;
            wr_en <= 1'b1;
            data_in <= data[index];
            if (index == 15)
            begin
                done <= 1; // all characters sent, stop
                index <= 0;
            end
            else
                index <= index + 1'b1;
        end
        else
        begin
            counter <= counter + 1;
            wr_en <= 0;
        end
    end
    else
        wr_en <= 0; // no more writes, text stays on screen
end

endmodule
