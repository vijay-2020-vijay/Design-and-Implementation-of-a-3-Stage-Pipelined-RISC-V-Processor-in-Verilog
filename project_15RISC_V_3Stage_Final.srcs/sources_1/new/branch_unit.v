`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
module branch_unit(
input[31:0]rs1_in,//comming from (integer_register_file)
input[31:0]rs2_in,//comming from (integer_register_file)
input[4:0]opcode_6_to_2_in,//comming from (instraction_mux)//here we will provide the opcode[6:2]//only 5 bits we will study accroding to its we can tak edecission
input[2:0]funct3_in,//comming from (instraction_mux)
output reg branch_taken_out//if high then branch has been taken ortherwise low//goes to  pc_mux and register_block2
);

////for b_typy ,jal and jalr instraction opcode_last 2 digits are 11 //so not need to declear again///////////////////////////
//////////////////////////////////for B_type instraction////////////////////////////////////////////////////////////////////
always@(*)begin
         if(opcode_6_to_2_in==5'b11000)begin
            case(funct3_in)
//////////////////BEQ_instraction/////////	Jump if rs1 == rs2///////////////////////////            
            3'b000:begin
              if(rs1_in==rs2_in) begin
                  branch_taken_out=1'b1;
              end
              else begin
                  branch_taken_out=1'b0;  
              end
            end
 ///////////////BNE instraction///////////	Jump if rs1 ≠ rs2//////////////////////////////////////////////////           
             3'b001:begin
              if(rs1_in!=rs2_in) begin
                  branch_taken_out=1'b1;
              end
              else begin
                  branch_taken_out=1'b0;  
              end
            end
///////////////BLT instraction//////////////Jump if rs1 < rs2 (signed)//////////////////////////////////////////////
            3'b100:begin
               if ((rs1_in[31] != rs2_in[31]) && rs1_in[31]==1'b1) begin // rs1 is negative, rs2 is positive → rs1 < rs2
                   branch_taken_out = 1'b1;
               end
               else if ((rs1_in[31] == 1'b0) && (rs2_in[31]==1'b0) && (rs1_in < rs2_in)) begin// Same sign, do normal unsigned compare
                   branch_taken_out = 1'b1;
               end 
               else if ((rs1_in[31] == 1'b1) && (rs2_in[31]==1'b1) && (rs1_in < rs2_in)) begin// Same sign, do normal unsigned compare
                   branch_taken_out = 1'b1;
               end 
               else begin
                   branch_taken_out = 1'b0;
               end
            end
//////////////BGE instraction//////////////Jump if rs1 ≥ rs2 (signed)/////////////////////////// ////////////////////      
            3'b101: begin
              if ((rs1_in[31] != rs2_in[31]) && rs1_in[31]!=1'b1) begin // rs1 is positive, rs2 is negative → rs1 >= rs2
                   branch_taken_out = 1'b1;
              end 
              
              else if ((rs1_in[31] == 1'b0)&& (rs2_in[31]==1'b0) && (rs1_in >= rs2_in)) begin // Same sign, do normal unsigned compare
                   branch_taken_out = 1'b1;
              end 
              else if ((rs1_in[31] == 1'b1)&& (rs2_in[31]==1'b1) && (rs1_in >= rs2_in)) begin // Same sign, do normal unsigned compare
                   branch_taken_out = 1'b1;
              end 
              
              else begin
              branch_taken_out = 1'b0;
             end
             end
//////////////////BLTU instraction//////////////Jump if rs1 < rs2 (unsigned)/////////////////////////////////////////////////////////////
           3'b110:begin
              if(rs1_in<rs2_in) begin
                  branch_taken_out=1'b1;
              end
              else begin
                  branch_taken_out=1'b0;  
              end
            end
 //////////////BGEU instraction/////////////Jump if rs1 ≥ rs2 (unsigned)///////////////////////////////////////////////////////////////////////////////    
            3'b111:begin
              if(rs1_in>=rs2_in) begin
                  branch_taken_out=1'b1;
              end
              else begin
                  branch_taken_out=1'b0;  
              end
            end
            default:begin
                 branch_taken_out=1'b0;  
            end
            endcase
         end   
////////////////////////////////////////////////////////////////////////////////////////////////////////   
        else if(opcode_6_to_2_in==5'b11011)begin ///for JAL instraction/////////////////////////
                branch_taken_out=1'b1;   
        end
        else if(opcode_6_to_2_in==5'b11001)begin///////for jalr instraction///////////////////
                branch_taken_out=1'b1;
        end
       else begin    
               branch_taken_out=1'b0;   
      end  
////////////////////////////////////////////////////////////////////////////////////////////////////
end  
endmodule
////////////////////////////////
