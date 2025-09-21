`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////The msrv32_store_unit module is responsible for handling store instructions (SB, SH, and SW) in a RISC-V processor.
//// Its main job is to prepare the correct data, memory address, write mask, and control signals for writing to memory.
// Purpose:
//This unit:
//	Accepts a data value (rs2_in) and a memory address (iadder_in)
//	Checks instruction type (funct3_in)
//	Based on alignment and type (byte, half-word, word), prepares:
//	Proper data layout
//	Proper write mask (which bytes should be written)
//	Control signals to initiate memory write
//	Aligned address (aligned to 4 bytes)
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
module store_unit(
input[1:0]funct3_in,//comes from the instraction field//indicates the data size(SW,SB,SH)//3-bit Specifies the store type: SB, SH, SW
input[31:0]iaddr_in,//memory address can be needed proper allignment//
input[31:0]rs2_in,//data comes from reg_block2 which should be stored//
input mem_wr_req_in,//memorey_write request sent from Decoder block//
input ahb_ready_in,//this control signal indicates memorey has been ready for writting
output reg[31:0]ms_ricv32_dmdata_out,//this is the actual data which need to be stored
output [31:0]ms_ricv32_mp_dmaddr_out,//this is the actual alligned address//this is also the effective address of the data memorey
output reg[3:0]ms_ricv32_mp_dmwr_mask_out,// which decide the size of the data(LB,HB,WB)is to be stored
output reg ms_ricv32_mp_dmwr_req_out,///enables memorey write
output reg[1:0]ahb_htrms_out// valid transfer and invalid transfer
);

assign ms_ricv32_mp_dmaddr_out={iaddr_in[31:2],2'b00}; ///aligned address is ready ///
assign ms_riscv32_mp_dmwr_req_out= mem_wr_req_in; 
always@(*)begin
       
       if(ahb_ready_in)begin
            case(funct3_in)
          
            3'b00:begin////for SB instraction
                   ahb_htrms_out=2'b10;//start to transfer
                   if(iaddr_in[1:0]==2'b00) begin
                      ms_ricv32_dmdata_out={24'd0,rs2_in[7:0]};///for SB instraction or byteable store lower bits captured
                      ms_ricv32_mp_dmwr_mask_out={3'b000,mem_wr_req_in};
                   end
                   else if(iaddr_in[1:0]==2'b01) begin
                      ms_ricv32_dmdata_out={16'd0,rs2_in[15:8],8'd0};///for SB instraction  or byteable store //middle bits captured
                      ms_ricv32_mp_dmwr_mask_out={2'b00,mem_wr_req_in,1'b0};
                   end
                   else if(iaddr_in[1:0]==2'b10) begin
                      ms_ricv32_dmdata_out={8'd0,rs2_in[23:16],16'd0};///for SB instraction  or byteable store //higher bits captured
                      ms_ricv32_mp_dmwr_mask_out={1'b0,mem_wr_req_in,2'b0};
                   end
                    else if(iaddr_in[1:0]==2'b11) begin
                      ms_ricv32_dmdata_out={rs2_in[31:24],24'd0};///for SB instraction  or byteable store //higher bits captured
                      ms_ricv32_mp_dmwr_mask_out={mem_wr_req_in,3'b0};
                   end
                   else begin
                      ms_ricv32_mp_dmwr_mask_out=4'd0;
                      ms_ricv32_dmdata_out=32'd0;
                      ahb_htrms_out=2'b00;//start to transfer
                      ms_ricv32_mp_dmwr_req_out=1'b0;//store is triggered  
                   end
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
     
            end
            3'b01:begin////////SH instraction
                  ahb_htrms_out=2'b10;//start to transfer
                  if(iaddr_in[1]==1'b0)begin
                       ms_ricv32_dmdata_out={16'd0,rs2_in[15:0]};//lower SH store
                       ms_ricv32_mp_dmwr_mask_out={2'b00,{2{mem_wr_req_in}}};
                  end
                  else begin
                       ms_ricv32_dmdata_out={16'd0,rs2_in[31:16]};//higher SH store 
                       ms_ricv32_mp_dmwr_mask_out={{2{mem_wr_req_in}},2'b00};
                  end           
            end
            
            3'b010:begin//////SW///////////////////////////////////////////////////////////////////////////////
                   ms_ricv32_dmdata_out=rs2_in[31:0];
                   ms_ricv32_mp_dmwr_mask_out={4{mem_wr_req_in}};
                   ahb_htrms_out=2'b10;//start to transfer
            end
            default:begin
                   ahb_htrms_out=2'b00;//no transfer
                   ms_ricv32_mp_dmwr_req_out=1'b0;
                   ms_ricv32_mp_dmwr_mask_out=4'd0;
                   ms_ricv32_dmdata_out=32'd0;       
            end
            endcase
       end
 //////////////////////////////////////////////////////////////////////////////////////////////////////////////////
       else begin
            ahb_htrms_out=2'b00;//no transfer
            ms_ricv32_mp_dmwr_req_out=1'b0;
            ms_ricv32_mp_dmwr_mask_out=4'd0;
            ms_ricv32_dmdata_out=32'd0;            
            
       end
end
endmodule
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// Summary in Plain Words:
///This module figures out how to format and where to send the data from register rs2_in to memory,
///depending on whether it's a byte, half-word, or word store.
///It aligns the address properly and ensures that only the necessary bytes are written in memory.
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////