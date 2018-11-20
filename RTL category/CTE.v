`timescale 1ns/10ps
module CTE ( clk, reset, op_mode, in_en, yuv_in, rgb_in, busy, out_valid, rgb_out, yuv_out);
input   clk ;
input   reset ;
input   op_mode;
input   in_en;
output  busy;
output  out_valid;
input   [7:0]   yuv_in;
output  [23:0]  rgb_out;
input   [23:0]  rgb_in;
output  [7:0]   yuv_out;

//Write your code here 

reg busy;
reg out_valid;
reg[2:0]cnt;

reg[12:0]yuv_in_arr[0:2]; //2+8bit+小數點3位
reg[12:0]rgb_preout_arr[0:2];
reg[7:0]rgb_out_arr[0:2];
reg[23:0]rgb_out;


reg[17:0]rgb_in_arr[0:2];
reg[17:0]yuv_preout_arr[0:2];
reg[7:0]yuv_out_arr[0:2];
reg[7:0]yuv_out;

//cnt
always@(posedge clk)begin
    if(reset)begin
        cnt <= 0;
    end
    if(in_en!=1)begin
        cnt <= 0;
    end
    
    else begin  
        cnt <= cnt +1;
    end    

    
    if(op_mode == 0)begin       //YUV to RGB

        if(cnt == 5)begin
            cnt <= 0;
        end
    end
    
    if(op_mode == 1)begin       //RGB to YUV
        if(cnt == 5)begin
            cnt <= 0;
        end
        
    end
   
end

//busy
always@(posedge clk)begin
    if(reset)begin
        busy <= 0;
    end
    busy <= 0;

    if(op_mode == 0)begin   // YUV to RGB

        if(cnt == 2)begin 
            busy <= 0;
        end
        if(cnt == 3)begin 
            busy <= 1;
        end
        if(cnt == 4)begin
            busy <= 1; 
        end
        if(cnt == 5)begin
            busy <= 0;
        end
    end    
    
    if(op_mode == 1)begin   //RGB to YUV

        if(cnt == 0)begin   //1停
            busy <= 1;
        end
        if(cnt == 1)begin   //2停
            busy <= 1;
        end
        if(cnt == 2)begin   //3停
            busy <= 1; 
        end
        if(cnt == 3)begin   //4繼續送
            busy <= 0;
        end
        if(cnt == 4)begin   //5停
            busy <= 1; 
        end
        if(cnt == 5)begin   //0停
            busy <= 0; 
        end
    end
end

//out_valid 
always@(negedge clk)begin
    if(reset)begin
        out_valid <= 0;
    end
    out_valid <= 0;

    if(op_mode == 0)begin   // YUV to RGB

        if(cnt == 3)begin
            out_valid <= 1;
        end
        if(cnt == 4)begin
            out_valid <= 1;
        end
    end 

    if(op_mode == 1)begin   //RGB to YUV
        if(cnt == 1)begin
            out_valid <= 1;
        end
        if(cnt == 2)begin
            out_valid <= 1;
        end
        if(cnt == 3)begin
            out_valid <= 1;
        end
        if(cnt == 4)begin
            out_valid <= 0;
        end
        if(cnt == 5)begin
            out_valid <= 1;
        end
    end
end

always@(negedge clk)begin    //rgb out
    if(cnt == 3)begin
        rgb_out = {rgb_out_arr[0],rgb_out_arr[1],rgb_out_arr[2]};
    end
    if(cnt == 4)begin
        rgb_out = {rgb_out_arr[0],rgb_out_arr[1],rgb_out_arr[2]};
    end
end

always@(posedge clk)begin   //yuv in arr

    if(cnt == 0)begin
        yuv_in_arr[1] <= {{2{yuv_in[7]}},yuv_in,3'b0};
    end
    if(cnt == 1)begin
        yuv_in_arr[0] <= {2'b00,yuv_in,3'b0};
    end
    if(cnt == 2)begin
        yuv_in_arr[2] <= {{2{yuv_in[7]}},yuv_in,3'b0};
    end
    if(cnt == 3)begin
        yuv_in_arr[0] <= {2'b00,yuv_in,3'b0};
    end
end

always@(*)begin     //YUV to RGB cal
    //R
    rgb_preout_arr[0] = {yuv_in_arr[0]}+
                        {yuv_in_arr[2]}+
                        {{yuv_in_arr[2][12]},yuv_in_arr[2][12:1]}+
                        {{3{yuv_in_arr[2][12]}},yuv_in_arr[2][12:3]};
    
    if(rgb_preout_arr[0][12])begin      //負數
        rgb_out_arr[0] = 8'b0;
    end
    else if(rgb_preout_arr[0][11]||rgb_preout_arr[0][10:2]==9'b111111111)begin //overflow
        rgb_out_arr[0] = 255;
    end
    else begin
        rgb_out_arr[0]  = rgb_preout_arr[0][10:3]+rgb_preout_arr[0][2];
    end
    
    //G
    rgb_preout_arr[1] = (   yuv_in_arr[0]-
                            {{2{yuv_in_arr[1][12]}},yuv_in_arr[1][12:2]}   )-
                        (   {yuv_in_arr[2][12],yuv_in_arr[2][12:1]}+
                            {{2{yuv_in_arr[2][12]}},yuv_in_arr[2][12:2]}   );
                        
    if(rgb_preout_arr[1][12])begin
        rgb_out_arr[1] = 8'b0;
    end
    else if(rgb_preout_arr[1][11]||rgb_preout_arr[1][10:2]==9'b111111111)begin //overflow
        rgb_out_arr[1] = 255;
    end
    else begin
        rgb_out_arr[1]  = rgb_preout_arr[1][10:3]+rgb_preout_arr[1][2];
    end
    
    //B
    rgb_preout_arr[2] = yuv_in_arr[0]+yuv_in_arr[1]+yuv_in_arr[1];
    
    if(rgb_preout_arr[2][12])begin
        rgb_out_arr[2] = 8'b0;
    end
    else if(rgb_preout_arr[2][11]||rgb_preout_arr[2][10:2]==9'b111111111)begin //overflow
        rgb_out_arr[2] = 255;
    end
    else begin
        rgb_out_arr[2]  = rgb_preout_arr[2][10:3]+rgb_preout_arr[2][2];
    end
end

/////////////////////////RGB to YUV///////////////////////////////

/*
always@(negedge clk)begin     //RGB to YUV out

    if(cnt==1)begin
        yuv_out <= yuv_out_arr[1];
    end
    if(cnt==2)begin
        yuv_out <= yuv_out_arr[0];
    end
    if(cnt==3)begin
        yuv_out <= yuv_out_arr[2];
    end
    if(cnt==5)begin
        yuv_out <= yuv_out_arr[0];
    end
    
end
*/

always@(*)begin     //RGB to YUV out
    
    case(cnt)
        3'd1:
            yuv_out = yuv_out_arr[1];
        3'd2:
            yuv_out = yuv_out_arr[0];
        3'd3:
            yuv_out = yuv_out_arr[2];
        3'd5:
            yuv_out = yuv_out_arr[0];
    endcase
end

always@(posedge clk)begin   //rgb in arr
    if(cnt == 3'd0 | cnt == 3'd4)begin
        rgb_in_arr[0] <= {10'b0,rgb_in[23:16]};
        rgb_in_arr[1] <= {10'b0,rgb_in[15:8]};
        rgb_in_arr[2] <= {10'b0,rgb_in[7:0]};
    end
end
    
always@(*)begin         //RGB to YUV out

    yuv_preout_arr[0] = 297*rgb_in_arr[0]+645*rgb_in_arr[1]+80*rgb_in_arr[2];
    yuv_out_arr[0] = yuv_preout_arr[0][17:10]+yuv_preout_arr[0][9];
    
    yuv_preout_arr[1] = -148*rgb_in_arr[0]-322*rgb_in_arr[1]+471*rgb_in_arr[2];
    yuv_out_arr[1] = yuv_preout_arr[1][17:10]+yuv_preout_arr[1][9];
    
    yuv_preout_arr[2] = 446*rgb_in_arr[0]-397*rgb_in_arr[1]-49*rgb_in_arr[2];
    yuv_out_arr[2] = yuv_preout_arr[2][17:10]+yuv_preout_arr[2][9];
    
end

endmodule


