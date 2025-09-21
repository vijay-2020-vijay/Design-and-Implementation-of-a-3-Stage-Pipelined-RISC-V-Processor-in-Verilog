`timescale 1ns / 1ps  
//////////////////////////////////////////////////////////////////////////////////
/////🧠 Functional Overview (What this module does):
//This module represents the register file in a RISC-V processor. It:
//•	Contains 32 general-purpose 32-bit registers
//•	Performs read operations on two source registers (rs1, rs2) during Phase 2
//•	Performs write operation on one destination register (rd) during Phase 3
//•	Implements data forwarding to reduce data hazards when rs1/rs2 == rd (read-after-write condition)
//•	Prevents writing to register x0 (hardwired to 0)
module msrv32_integer_file(
input ms_riscv_32_mp_clk_in,//coming from the top module
input ms_riscv_32_mp_rst_in,//coming from the top module
input[4:0]rs_2_addr_in,//register source address1//(coming from instraction_mux) //this willbe coming phase2
input[4:0]rd_addr_in,//register destinetion address//(coming from reg_block 2) //this willbe coming phase3
input wr_en_in,//write enable control signal comming from(wr_en_generetor)//this give the response at the phase 3
input[31:0]rd_in,//data is to be written to the destinetion register address(from wb_mux)//at the write back stage//phase 3
input[4:0]rs_1_addr_in,//register source address1//(coming from instraction_mux) //this willbe coming phase2
output [31:0]rs_1_out,//data_read(rs1)//going to reg_block_2,immediate_adder,branch_unit
output [31:0]rs_2_out//data_read(rs2)//going to reg_block_2,store_unit,branch_unit
);
//////////////////////////////basic funtionality of this code//////////////////////////////////////////////////////////////////////////
//1.it has 32 GPR which will be performed as read and write operation//register read address will be provided at phase2 by instraction_mux unit
//write operation will be performed at phase 3
//2.initial values of all the registers should be zero.the ist register value hard_wirely written as 0 one time.so no write operation will be performed to reg[0]
//location//A forword mechanisim handles hazards when both read and write refer to same address.
// at stage 3 :write reques is sent to the register which is being read at stage 2.
reg[31:0]reg_file[31:0];//32*32 register file//GPR
///////////////write logic in stage 3//////////////will be performed/////////////
always@(posedge ms_riscv_32_mp_clk_in)begin
       reg_file[0]<=32'd0;
       if(ms_riscv_32_mp_rst_in) begin  ////////////just initializetion of the register_file
        reg_file[1]<=32'd0;
        reg_file[2]<=32'h2f000;      
        reg_file[3]<=32'd0;
        reg_file[4]<=32'd0; 
        reg_file[5]<=32'd0;
        reg_file[6]<=32'd0;  
        reg_file[7]<=32'd0;
        reg_file[8]<=32'd0;      
        reg_file[9]<=32'd0;
        reg_file[10]<=32'd0;
        reg_file[11]<=32'd0;      
        reg_file[12]<=32'd0;
        reg_file[13]<=32'd0; 
        reg_file[14]<=32'd0;
        reg_file[15]<=32'd0;  
        reg_file[16]<=32'd0;
        reg_file[17]<=32'd0;      
        reg_file[18]<=32'd0;
        reg_file[19]<=32'd0;
        reg_file[20]<=32'd0;      
        reg_file[21]<=32'd0;
        reg_file[22]<=32'd0;
        reg_file[23]<=32'd0; 
        reg_file[24]<=32'd0;
        reg_file[25]<=32'd0;  
        reg_file[26]<=32'd0;
        reg_file[27]<=32'd0;      
        reg_file[28]<=32'd0;
        reg_file[29]<=32'd0;
        reg_file[30]<=32'd0;
        reg_file[31]<=32'd0;
        end
        
       else if( wr_en_in && rd_addr_in !=5'd0) begin  //////////////reg_file[0] in this location writting is not performed
             reg_file[rd_addr_in]<=rd_in;
       end 
       else begin
            reg_file[rd_addr_in]<=reg_file[rd_addr_in] ;
       end
end
//////////////////////read operation and data forwording technique how it helps to reduce the data hazard/ at phase 2///////////////////////
/////////////////////////////////for  rs_1_out///////////////////////////////////
assign rs_1_out=(wr_en_in && !(rs_1_addr_in^rd_addr_in) && (rd_addr_in != 0))? rd_in:reg_file[rs_1_addr_in];
assign rs_2_out=(wr_en_in && !(rs_2_addr_in^rd_addr_in)&&(rd_addr_in != 0))? rd_in:reg_file[rs_2_addr_in];

                                                                                     
endmodule
/////////////////////////////////////////////////////////////////////////////////////////////////////

