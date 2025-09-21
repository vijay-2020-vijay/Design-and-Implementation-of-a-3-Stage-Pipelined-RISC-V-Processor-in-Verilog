
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Purpose:
//To decode memory data based on RISC-V load instructions and return a properly extended 32-bit value (either sign-extended or zero-extended), 
//depending on the instruction.

module load_unit(
input ahb_rsep_in,//tells memorey access has benn happened or not.that means oncce data memorey is come.then approprite load operation will be doimg.
//active low signal used load the external data from the memorey.//(coming from data memorey)
input[31:0]ms_riscv32_mp_dmdata_in,//32 bit data has been read from data memorey//now this data will be modifited to the different load_type of operation like 
////LB,LH,LW,LBU,LHU .//(from external data memorey)
input[1:0]iadder_out_1_to_0_in,// it takes last two bits of the effective address//determines the offset within 32 bit word.these are needed to pick the 
//right byte or half word when useing LB,LH,LBU,LHU //(comming from reg_block_2)
input load_unsigned_in,//funct3[2]//decide which kind of Load instraction it is//(coming from register block 2)
input[1:0]load_size_in,//funct3[1:0]//decide which kind of Load instraction it is//(coming from register block 2)
input clk,
output reg[31:0] lu_output_out//32 bit output data which is going to the integer file.
);
reg[7:0] byte;
reg[15:0] half_word;
reg[31:0] lu_output_out1;
always@( posedge clk)begin
      if(!ahb_rsep_in) begin
         case(load_size_in)
////////////////////////////////////////////////////////////////////////////////////////////         
         2'd0:begin/////for LB instraction//which is in signed formet
             case(iadder_out_1_to_0_in)
             2'b00:begin
                  byte=ms_riscv32_mp_dmdata_in[7:0];
             end
             2'b01:begin
                  byte=ms_riscv32_mp_dmdata_in[15:8];
             end
             2'b10:begin
                  byte=ms_riscv32_mp_dmdata_in[23:16];
             end
             2'b11:begin
                  byte=ms_riscv32_mp_dmdata_in[31:24];
             end
             default:begin
                  byte=8'd0;
             end
             endcase
             if(load_unsigned_in==1'b0) begin
                 lu_output_out={{24{byte[7]}}, byte};
             end  
             else
                 lu_output_out={24'd0, byte};
         end
 /////////////////////////////////////////////////////////////////////////////////////////////
         3'd1:begin////for LH instraction
               case(iadder_out_1_to_0_in)
               2'b00:begin
                    half_word=ms_riscv32_mp_dmdata_in[15:0];
               end
               2'b10:begin
                    half_word=ms_riscv32_mp_dmdata_in[31:16];
               end
               default:begin
                    half_word=16'd0;
               end
               endcase
               if(load_unsigned_in==1'b0) begin
                   lu_output_out={{16{half_word[7]}}, half_word};
               end  
               else
                   lu_output_out={16'd0,half_word};
         end
 //////////////////////////////////////////////////////////////////////////////////////////////////        
         3'd2:begin////for LW instraction
               lu_output_out=ms_riscv32_mp_dmdata_in;
         end
         3'd3:begin////for LW instraction
               lu_output_out=ms_riscv32_mp_dmdata_in;
         end
//////////////////////////////////////////////////////////////////////////////////////////////////         
         default:begin
               lu_output_out=32'd0;
         end
///////////////////////////////////////////////////////////////////////////////////////////         
         endcase        
   end
   else
              lu_output_out=32'd0; 

end
endmodule