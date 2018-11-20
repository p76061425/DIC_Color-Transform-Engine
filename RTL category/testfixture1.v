`timescale 1ns/10ps
`define CYCLE    100           	         // Modify your clock period here
`define PAT      "./pattern_yuv.dat"    
`define EXP      "./golden_rgb.dat"     

module test;
parameter N_EXP   = 500;
parameter N_PAT   = N_EXP*2;

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

reg   [7:0]   pat_mem   [0:N_PAT-1];
reg   [23:0]  exp_mem   [0:N_EXP-1];
reg   [23:0]  out_temp;

reg           stop;
integer       i, out_f, err, pass, exp_num;
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
   rgb_in      = 'hz;
   stop        = 1'b0;  
   over        = 1'b0;
   exp_num     = 0;
   err         = 0;
   pass        = 0;            
end

always begin #(`CYCLE/2) clk = ~clk; end

initial begin
//$dumpfile("CTE1.vcd");
//$dumpvars;
//$fsdbDumpfile("CTE1.fsdb");
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
         yuv_in = pat_mem[i];
         in_en = 1'b1;
         i=i+1;
      end 
      else begin
         yuv_in = 'hz; 
      end                    
      @(negedge clk); 
    end     
    in_en = 0; stop = 1 ;  
end

always @(posedge clk)begin
   out_temp = exp_mem[exp_num];
   if(out_valid)begin
      $fdisplay(out_f,"%6h", rgb_out);      
      if(rgb_out !== out_temp) begin
         $display("ERROR at %3d:output %6h !=expect %6h " ,exp_num, rgb_out, out_temp);
         err = err + 1 ;  
      end            
      else begin      
         pass = pass + 1 ;
      end      
      #1 exp_num = exp_num + 1;
   end
   if(exp_num === N_EXP)  over = 1'b1;         
end


initial begin
      @(posedge stop or posedge over)      
      if((over) && (exp_num!='d0)) begin
         $display("-----------------------------------------------------\n");
         if (err == 0)  begin
            $display("Congratulations! All data have been generated successfully!\n");
            $display("-------------Function 1 (YUV->RGB) PASS--------------------\n");
         end
         else begin
            $display("There are %d errors!\n", err);
            $display("-----------------------------------------------------\n");
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









