`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
////The msrv32_alu module is a 32-bit Arithmetic Logic Unit (ALU) written in Verilog for a RISC-V core. 
//It performs arithmetic and logic operations on two 32-bit operands based on a 4-bit operation code (opcode_in).
// Here's a detailed functional breakdown of what each part of this module does:
module ALU(
input[31:0]op_1_in,//ist operation for operand(coming from the register block 2)
input[31:0]op_2_in,//2nsd operand for operation (coming from WB_MUX)
input[3:0]opcode_in,//this signal is driven by funct7 and funct3 instraction fields(from register block 2)//also tells the alu which operation should be performed
output reg[31:0]result_out//result of the requested operation( to the WB_MUX block)
);

always@(*)begin
         case(opcode_in)
         4'd0:begin
             result_out=op_1_in+op_2_in;//alu_add
         end
         4'd8:begin
             result_out=op_1_in-op_2_in;//alu_sub
         end
//////////////////////////////////////////////////////////////////////////////////         
         4'd2:begin///alu_slt//for signed case
              if ((op_1_in[31] != op_2_in[31]) && op_1_in[31]==1'b1) begin // rs1 is negative, rs2 is positive → rs1 < rs2
                  result_out = 1'b1;
               end
               else if ((op_1_in[31] == 1'b0) && (op_2_in[31]==1'b0) && (op_1_in < op_2_in)) begin// Same sign, do normal unsigned compare
                  result_out = 1'b1;
               end 
               else if ((op_1_in[31] == 1'b1) && (op_2_in[31]==1'b1) && (op_1_in < op_2_in)) begin// Same sign, do normal unsigned compare
                  result_out = 1'b1;
               end 
               else begin
                  result_out = 1'b0;
               end
         end
         4'd3:begin///alu_sltu//for unsigned case
              if(op_1_in<op_2_in)begin
                 result_out=32'd1;
              end
              else begin
                 result_out=32'd0;
              end
 ////////////////////////////////////////////////////////////////////////////////////                 
         end
         4'd7:begin
             result_out=op_1_in & op_2_in;
         end
         4'd6:begin
             result_out=op_1_in | op_2_in;
         end
         4'd4:begin
             result_out=op_1_in ^ op_2_in;
         end
         4'd1:begin///SLL //logical left shift
             result_out=op_1_in << op_2_in[4:0];
         end
         4'd5:begin//srl//logical right shift
             result_out=op_1_in >> op_2_in[4:0];
         end
         4'd13:begin//ALU_SRA//Arithimetic right shift
             result_out=op_1_in>>>op_2_in[4:0];
         end
         default:begin
            result_out=op_1_in+op_2_in;
         end
         endcase
end
endmodule
