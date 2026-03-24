module LCD_driver_top(clk,sw,JB,JA);
                   
input clk;             
input [15:0] sw;
output  [7:0] JB;
output [7:0] JA;

parameter clk_param =16000000;//How long is it? 16000000 counts/100000000 counts/s = 0.16 s
   
reg [7:0] data [15:0];
reg [7:0] data_in;
//wire [7:0] data_in;
integer counter=0;
reg [3:0] index=0;
reg wr_en=0;
    
LCD_driver_2 lcd1(.clk(clk),.wr_en(wr_en),.data_in(data_in),
.data_out(JA),.en(JB[0]),.rs(JB[2]));
    
always @ (posedge clk)
begin
        if (counter >= clk_param)
        begin
            counter <= 0;
            wr_en<=1'b1;
            data_in<=data[index];
            index<=index+1'b1;
        end
        else
        begin
            counter <= counter + 1;
            wr_en<=0;
        end  
end                  

always @ (posedge clk)
case (sw[7:0])
8'h01:
begin // SKYHAWK
data[0]<="S"; data[1]<="K"; data[2]<="Y"; data[3]<="H";
data[4]<="A"; data[5]<="W"; data[6]<="K"; data[7]<=" "; 
data[8]<=" "; data[9]<=" "; data[10]<=" "; data[11]<=" "; 
data[12]<=" "; data[13]<=" "; data[14]<=" "; data[15]<=" "; 
end
8'h02:
begin // FORT LEWIS
data[0]<="F"; data[1]<="O"; data[2]<="R"; data[3]<="T";
data[4]<=" "; data[5]<="L"; data[6]<="E"; data[7]<="W"; 
data[8]<="I"; data[9]<="S"; data[10]<=" "; data[11]<=" "; 
data[12]<=" "; data[13]<=" "; data[14]<=" "; data[15]<=" "; 
end
8'h04:
begin // COLLEGE
data[0]<="C"; data[1]<="O"; data[2]<="L"; data[3]<="L";
data[4]<="E"; data[5]<="G"; data[6]<="E"; data[7]<=" "; 
data[8]<=" "; data[9]<=" "; data[10]<=" "; data[11]<=" "; 
data[12]<=" "; data[13]<=" "; data[14]<=" "; data[15]<=" "; 
end
8'h08:
begin // DURANGO
data[0]<="D"; data[1]<="U"; data[2]<="R"; data[3]<="A"; 
data[4]<="N"; data[5]<="G"; data[6]<="O"; data[7]<=" "; 
data[8]<=" "; data[9]<=" "; data[10]<=" "; data[11]<=" "; 
data[12]<=" "; data[13]<=" "; data[14]<=" "; data[15]<=" "; 
end       
8'h10:
begin // USA
data[0]<="U"; data[1]<="S"; data[2]<="A"; data[3]<=" ";
data[4]<=" "; data[5]<=" "; data[6]<=" "; data[7]<=" "; 
data[8]<=" "; data[9]<=" "; data[10]<=" "; data[11]<=" "; 
data[12]<=" "; data[13]<=" "; data[14]<=" "; data[15]<=" ";
end
8'h20:
begin // COLORADO
data[0]<="C"; data[1]<="O"; data[2]<="L"; data[3]<="O";
data[4]<="R"; data[5]<="A"; data[6]<="D"; data[7]<="O"; 
data[8]<=" "; data[9]<=" "; data[10]<=" "; data[11]<=" "; 
data[12]<=" "; data[13]<=" "; data[14]<=" "; data[15]<=" "; 
end
8'h40:
begin // FPGA
data[0]<="F"; data[1]<="P"; data[2]<="G"; data[3]<="A";
data[4]<=" "; data[5]<=" "; data[6]<=" "; data[7]<=" "; 
data[8]<=" "; data[9]<=" "; data[10]<=" "; data[11]<=" "; 
data[12]<=" "; data[13]<=" "; data[14]<=" "; data[15]<=" ";
end
8'h80:
begin // HOLA
data[0]<="H"; data[1]<="O"; data[2]<="L"; data[3]<="A";
data[4]<=" "; data[5]<=" "; data[6]<=" "; data[7]<=" "; 
data[8]<=" "; data[9]<=" "; data[10]<=" "; data[11]<=" "; 
data[12]<=" "; data[13]<=" "; data[14]<=" "; data[15]<=" ";
end
default:    
begin // MAKE A SELECTION - HAS UNA ELECCION
data[0]<="H"; data[1]<="E"; data[2]<="L"; data[3]<="L"; 
data[4]<="O"; data[5]<=" "; data[6]<=" "; data[7]<=" "; 
data[8]<=" "; data[9]<=" "; data[10]<=" "; data[11]<=" "; 
data[12]<=" "; data[13]<=" "; data[14]<=" "; data[15]<=" ";
end
endcase

endmodule

