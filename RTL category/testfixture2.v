`timescale 1ns/10ps
`define CYCLE    100                      	// Modify your clock period here
`define PAT      "./pattern_rgb1.dat"		// Modify the test pattern
`define EXP      "./golden_yuv1.dat"

module test;
parameter N_PAT   = 500;
parameter N_EXP   = N_PAT*2;


reg   clk ;
reg   reset ;
reg   op_mode;
reg   in_en;
reg   [7:0]   yuv_in;
reg   [23:0]  rgb_in;
wire  busy;
wire  out_valid;
wire  [23:0]  rgb_out;
wire  [7:0]   yuv_out;

reg   [23:0]  pat_mem   [0:N_PAT-1];
reg   [7:0]   exp_mem   [0:N_EXP-1];
reg   [7:0]   out_temp;
reg   [7:0]   t1, t2;

reg           stop;
integer       i, j, k, distance, out_f, exp_num;
integer       total, error;
real          x, y, total_error;
reg           over;

   CTE CTE( .clk(clk), .reset(reset), .op_mode(op_mode), .in_en(in_en),
            .yuv_in(yuv_in), .rgb_in(rgb_in), .busy(busy), .out_valid(out_valid),
            .rgb_out(rgb_out), .yuv_out(yuv_out)); 


//initial $sdf_annotate(`SDFFILE, CTE);
initial	$readmemh (`PAT, pat_mem);
initial	$readmemh (`EXP, exp_mem);


initial begin
   clk         = 1'b0;
   reset       = 1'b0;
   op_mode     = 1'b0;
   in_en       = 1'b0;  
   yuv_in      = 'hz;    
   stop        = 1'b0;  
   over        = 1'b0;
   exp_num     = 0;
   error       = 100000;
   total_error = 0;
   distance    = 0;
   total       = 0;   
   j           = 0;   //for YUV signal order
   k           = 1;   //for YUV signal number
end

always begin #(`CYCLE/2) clk = ~clk; end

initial begin
//$dumpfile("CTE2.vcd");
//$dumpvars;
//$fsdbDumpfile("CTE2.fsdb");
//$fsdbDumpvars;

   out_f = $fopen("out.dat");
   if (out_f == 0) begin
        $display("Output file open error !");
        $finish;
   end
end


initial begin
   @(negedge clk)  reset = 1'b1;
   #`CYCLE         reset = 1'b0;
   
   #(`CYCLE*2);
   @(negedge clk)    i=0;
    while (i <= N_PAT) begin               
      if(!busy) begin
         rgb_in = pat_mem[i];
         op_mode  = 1'b1;
         in_en = 1'b1;
         i=i+1;
      end 
      else begin
         rgb_in = 'hz; 
      end                    
      @(negedge clk); 
    end     
    in_en = 0; stop = 1 ;  
end

always @(posedge clk)begin
   out_temp = exp_mem[exp_num];
   if(out_valid)begin
      $fdisplay(out_f,"%2h", yuv_out);           
            
      if((exp_num%4==1) || (exp_num%4==3))begin   //Y Signal distance
         error=out_temp-yuv_out;
      end
      
      else begin   //U V Signal distance                 
         if(yuv_out[7]==0 && out_temp[7]==0)     begin  error=out_temp-yuv_out;                          end
         else if(yuv_out[7]==0 && out_temp[7]==1)begin  t1=~out_temp; error=-(t1+1)-yuv_out;             end
         else if(yuv_out[7]==1 && out_temp[7]==0)begin  t1=~yuv_out;  error=out_temp+t1+1;               end
         else                                    begin  t1=~out_temp; t2=~yuv_out; error=-(t1+1)+(t2+1); end  
      end                             
      
      distance=distance+error*error;
      total=total+out_temp*out_temp;
      if(j==0)begin
         if(error !=0 || error === 'hx || error === 'hz)begin
            $display("ERROR at %3d: Signal U%3d => output:%2h v.s. expect:%2h    error(distance):%3d" , exp_num, k, yuv_out, out_temp, error);
         end
         j=1;   k=k;
      end
      
      else if(j==1)begin
         if(error !=0 || error === 'hx || error === 'hz)begin
            $display("ERROR at %3d: Signal Y%3d => output:%2h v.s. expect:%2h    error(distance):%3d" , exp_num, k, yuv_out, out_temp, error);
         end
         j=2;   k=k;
      end
      
      else if(j==2)begin
         if(error !=0 || error === 'hx || error === 'hz)begin
            $display("ERROR at %3d: Signal V%3d => output:%2h v.s. expect:%2h    error(distance):%3d" , exp_num, k, yuv_out, out_temp, error);
         end
         j=3;   k=k+1;
      end
      
      else if(j==3)begin
         if(error !=0 || error === 'hx || error === 'hz)begin
            $display("ERROR at %3d: Signal Y%3d => output:%2h v.s. expect:%2h    error(distance):%3d" , exp_num, k, yuv_out, out_temp, error);
         end
         j=0;   k=k+1;
      end      
      exp_num = exp_num + 1;
   end
   if(exp_num === N_EXP)  over = 1'b1;
end


initial begin
      @(posedge stop or posedge over)      
      if(exp_num!==0 && distance!=='hx && distance!=='hz ) begin
            error=distance;
            x=distance;   //change format into real
            y=total;      //change format into real
            total_error=x/y;

            $display("-----------------------------------------------------\n");
            $display("Square Distance of All YUV = %f\n", x);
            $display("Square of All YUV Signal   = %f\n", y);
            $display("-----------------------------------------------------\n");
            $display("So Your Error Ratio:\n\n(Square Distance of YUV)/(Square of All YUV Signal) = %f\n",total_error);
            $display("-----------------------------------------------------\n");

         if(error<0.00002*y && error!=='hx && error!=='hz)begin                           
            $display("Your Score Level: A \n");  
            $display("Congratulations! CTE's Function2 Successfully!\n");
            $display("-------------------------PASS------------------------\n");
         end
         else if(error>=0.00002*y && error <0.00005*y && error!=='hx && error!=='hz)begin
            $display("Your Score Level: B \n");
            $display("Congratulations! CTE's Function2 Successfully!\n");
            $display("-------------------------PASS------------------------\n");
         end
         else if(error>=0.00005*y && error <0.00010*y && error!=='hx && error!=='hz)begin
            $display("Your Score Level: C \n");
            $display("Congratulations! CTE's Function2 Successfully!\n");
            $display("-------------------------PASS------------------------\n");
         end
         else if(error>=0.00010*y && error <0.00050*y && error!=='hx && error!=='hz)begin
            $display("Your Score Level: D \n");
            $display("Congratulations! CTE's Function2 Successfully!\n");
            $display("-------------------------PASS------------------------\n");
         end
         else if(error>=0.00050*y && error <0.00300*y && error!=='hx && error!=='hz)begin
            $display("Your Score Level: E \n");
            $display("Congratulations! CTE's Function2 Successfully!\n");
            $display("-------------------------PASS------------------------\n");
         end
         else begin
            $display("Your Score Level: F \n");                  
            $display("-------------   CTE's Function2 Fail   -------------\n");
            $display("-------------------------Fail------------------------\n");
         end
      end
      else begin
        $display("-----------------------------------------------------\n");
        $display("Error!!! Somethings' wrong with your code ...!\n");
        $display("-------------------------FAIL------------------------\n");
        $display("-----------------------------------------------------\n");
      end
      #(`CYCLE/2); $finish;
end
   
endmodule









