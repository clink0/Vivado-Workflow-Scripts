module LCD_driver(clk, data_in, data_out, wr_en, en, rs);
input clk;
input [7:0] data_in;
input wr_en;
output reg [7:0] data_out;
output reg en;
output reg rs;
reg [1:0] init_cnt;
reg [7:0] init[3:0];
localparam INIT=2'b00, WAIT=2'b01, WRITE=2'b10;
reg [1:0] state = INIT;
integer cnt_setup=0;
reg [3:0] cnt_data_in;
parameter cntmax_setup=100000;
parameter cntmax_data_in=15;
localparam cntmax_init=3;
initial
begin
	init[0]=8'h30;
	init[1]=8'h01;
	init[2]=8'h06;
	init[3]=8'h0F;
end
always@(negedge clk)
begin
    rs<=1;
    en<=1;
    begin
        case(state)
        INIT:
        begin
            rs<=0;
            data_out<=init[init_cnt];
            if(cnt_setup >= cntmax_setup)
            begin
                cnt_setup<=0;
                en<=0;
                init_cnt<=init_cnt+1;
                if(init_cnt==cntmax_init)
                begin
                    init_cnt<=0;
                    state<=WAIT;
                end
            end
            else
                cnt_setup<=cnt_setup+1;
        end
        WAIT:
        begin
            if(wr_en==1)
            state<=WRITE;
        end
        WRITE:
        begin
            data_out<=data_in;	
            if(cnt_setup>=cntmax_setup)
            begin
                en<=0;
                cnt_setup<=0;	
                cnt_data_in<=cnt_data_in+1;
                if(cnt_data_in==cntmax_data_in)
                begin
                    // Task 2: stay in WAIT instead of going back to INIT
                    // this keeps the text steady on screen
                    cnt_data_in<=0;
                    state<=WAIT;
                end
                else
                    state<=WAIT;
            end
            else
                cnt_setup<=cnt_setup+1;
        end
        endcase
    end
end
endmodule
