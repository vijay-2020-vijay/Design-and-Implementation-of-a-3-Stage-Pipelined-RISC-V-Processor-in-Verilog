`timescale 1ns / 1ps
////////////////////// fwrite //////////////////////////////////////////////////

module fwrite_file1(

 

    input        clk,

    input        reset,

    input        rd_en,//after decode (write enable signal from decoder-->rf_wr_en_out1)

    input [4:0]  rd_add,

    input [31:0] pc,//current instruction address(pc_out1 (pc_in)current pc from pc mux)

    input is_load, // 3 ports added for verification for fwrite file from decoder


    input is_store,

    input load_unsignned_in,// 2 ports from load unit

    input [1:0] load_size_in,


    input [31:0] mem_radd,//address from write back mux, iadder_out_reg_out1

    input [1:0] funct3_in,// from store unit


    input [31:0] mem_wadd,

    input [31:0] mem_wdata,


    input        wrd_en1,

    input [ 4:0] wrd_add1,// changed from 6 to 4

    input [31:0] wrd_data1


);

 

wire [2:0]  mem_ren;

   
//3 lines added for verification (memory read enable signals devrived from load unit)

   assign mem_ren[0]= ((load_size_in==2'b00)&& (is_load==1'b1)) ? 1:0;

   assign mem_ren[1]= ((load_size_in==2'b01)&& (is_load==1'b1)) ? 1:0;

   assign mem_ren[2]= ((load_size_in==2'b10|load_size_in==2'b11)&& (is_load==1'b1)) ? 1:0;// changed added --> |(load_size_in==2'b10)

  // 3 lines added for verification (memory read enable signals devrived from store unit)

  wire [2:0]  mem_wen;

  assign mem_wen[0]= ((funct3_in==2'b00) && (is_store==1'b1))? 1:0;

   assign mem_wen[1]= ((funct3_in==2'b01) && (is_store)==1'b1)? 1:0;

   assign mem_wen[2]= ((funct3_in==2'b10|funct3_in==2'b11)&& (is_store)==1'b1)  ? 1:0;

 

// ---------------        Reg Status Write (Simulation Only)    -------------------- //


    reg        reg_rd_en ; always@(posedge clk) reg_rd_en  <= rd_en ;


    reg [4:0]  reg_rd_add; always@(posedge clk) reg_rd_add <= rd_add ;


    reg [31:0] reg_pc        ; always@(posedge clk) reg_pc         <= pc ;

    reg [ 2:0] reg_mem_ren   ; always@(posedge clk) reg_mem_ren    <= mem_ren ;

    reg [ 2:0] reg_mem_wen   ; always@(posedge clk) reg_mem_wen    <= mem_wen ;


 

    

    reg [31:0] reg_mem_radd  ; always@(posedge clk) if (mem_ren!=0) reg_mem_radd  <= mem_radd ; else reg_mem_radd  <= 0;

    reg [31:0] reg_mem_wadd  ; always@(posedge clk) if (mem_wen!=0) reg_mem_wadd  <= mem_wadd ; else reg_mem_wadd  <= 0;

    reg [31:0] reg_mem_wdata ; always@(posedge clk) 


        if      (mem_wen[0])

          begin

           case(mem_wadd[1:0])

                    2'b00: begin

                            reg_mem_wdata <= {24'd0,mem_wdata[7:0]}; 

                            end

                    2'b01: begin

                            reg_mem_wdata<={8'b0,8'b0,8'b0,mem_wdata[15:8]};


                            end

                    2'b10: begin 

                            reg_mem_wdata<={8'b0,8'b0,8'b0,mem_wdata[23:16]};


                           end

                    2'b11: begin

                             reg_mem_wdata={8'b0,8'b0,8'b0,mem_wdata[31:24]};


                           end

                    endcase

                  end


        else if (mem_wen[1])

          begin

              if(mem_wadd[1]==1)

                          begin

                            reg_mem_wdata<={16'b0,mem_wdata[31:16]};


                          end

                            else

                          begin

                           reg_mem_wdata <= {16'd0,mem_wdata[15:0]}; 


                          end

                       end 

        else if (mem_wen[2]) reg_mem_wdata <= mem_wdata; 

        else                 reg_mem_wdata <= 0;

 

    integer write_file;

    initial begin


        write_file = $fopen("D:/verilog_11/project_15RISC_V_3Stage_Final/result_status.txt","w");// used location in sever

        //write_file = $fopen("C:/Xilinx/reg_status_hw_3stage_32kb.txt","w");


        $fdisplay(write_file, "pc       (rd rd  wdata   ) (wen wadd     wdata    | radd    )");

        $fclose(write_file);

    end


    wire[4:0] wire_rd_add = reg_rd_add[4:0] ;


    wire vrd_en = reg_rd_en & (wire_rd_add!=0) ; 


    wire [23:0] reg_name = (wire_rd_add==01) ? " ra" : (wire_rd_add==02) ? " sp" : (wire_rd_add==03) ? " gp" : (wire_rd_add==04) ? " tp"

    :                      (wire_rd_add==05) ? " t0" : (wire_rd_add==06) ? " t1" : (wire_rd_add==07) ? " t2" : (wire_rd_add==08) ? " s0"

    :                      (wire_rd_add==09) ? " s1" : (wire_rd_add==10) ? " a0" : (wire_rd_add==11) ? " a1" : (wire_rd_add==12) ? " a2"

    :                      (wire_rd_add==13) ? " a3" : (wire_rd_add==14) ? " a4" : (wire_rd_add==15) ? " a5" : (wire_rd_add==16) ? " a6"

    :                      (wire_rd_add==17) ? " a7" : (wire_rd_add==18) ? " s2" : (wire_rd_add==19) ? " s3" : (wire_rd_add==20) ? " s4"

    :                      (wire_rd_add==21) ? " s5" : (wire_rd_add==22) ? " s6" : (wire_rd_add==23) ? " s7" : (wire_rd_add==24) ? " s8"

    :                      (wire_rd_add==25) ? " s9" : (wire_rd_add==26) ? "s10" : (wire_rd_add==27) ? "s11" : (wire_rd_add==28) ? " t3"

    :                      (wire_rd_add==29) ? " t4" : (wire_rd_add==30) ? " t5" : (wire_rd_add==31) ? " t6" :                    "  0" ;


    always@(posedge clk) begin

        if ( vrd_en ) begin

            write_file = $fopen("D:/verilog_11/project_15RISC_V_3Stage_Final/result_status.txt","a");// used location in server

            //write_file = $fopen("C:/Xilinx/reg_status_hw_3stage_32kb.txt","a");

            $fdisplay(write_file, "%h (%02d %s %h) (%b %h %h | %h)",reg_pc,wire_rd_add,reg_name,wrd_data1,3'd0,32'd0,32'd0,reg_mem_radd);//modified one


            $fclose(write_file);

        end else if ( reg_mem_wen!=0 ) begin

            write_file = $fopen("D:/verilog_11/project_15RISC_V_3Stage_Final/result_status.txt","a");// used location in server

            //write_file = $fopen("C:/Xilinx/reg_status_hw_3stage_32kb.txt","a");

            $fdisplay(write_file, "%h (%02d %s %h) (%b %h %h | %h)",reg_pc,0,"000",32'd0,reg_mem_wen,reg_mem_wadd,reg_mem_wdata,reg_mem_radd);


            $fclose(write_file);

        end 

    end
    
 
endmodule
