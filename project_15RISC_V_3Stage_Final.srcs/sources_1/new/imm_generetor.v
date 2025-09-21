
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps
///////////////////////////////this module will generate immediate value for all kin dof instraction///////////////////////////////////////////////////
/////////////////////////////////Module Purpose///////////////////////////////////////////////////////////////////////////////////////////////////////
//This module extracts and generates the 32-bit immediate value from a given instruction (instr_in[31:7]) based on the type of instruction (imm_type_in).
//It supports all major RISC-V instruction types: R, I, S, B, U, J, CSR.


module imm_generetor(
input[24:0]instr_in,//this 25 bits port will capture the instraction[31:7]//once we instantiate to anywhere we have to provide instraction[31:7]
///this will be coming from (instraction_mux) block.
input[2:0]imm_type,//this is control signal which will decide,what kind of instraction's immediate value should be generated//comming from decoder block
output reg[31:0]imm_out///this is final 32 bit immediate value goes to (Register_block_2) and (immediate_adder block).
);
wire[31:0]r_type;///no existence of imm_value
wire[31:0]i_type;///istraction_code[31:20] so  we have to capture instr_in[24:13]
wire[31:0]s_type;//istraction_code[31:25]+istraction_code[11:7]///so here we should do: instr_in[24:18]+ instr_in[4:0]
wire[31:0]b_type;//istraction_code[7]+istraction_code[30:25]+istraction_code[11:8],1'b0;
//// thats why we have to set like this:: instr_in[0]+instr_in[23:18]+instr_in[4:1]+1'b0
wire[31:0]u_type;//istraction_code[31:12],12'h000///instr_in[24:5]+12'h000;
wire[31:0]j_type;//istraction_code[19:12]+istraction_code[20]+istraction_code[30:21]+1'b0;//instr_in[12:5]+instr_in[13]+instr_in[23:14]+1'b0
wire[31:0]csr_type;//istraction_code[19:15]//instr_in[12:8]
//////////////////////////////////////////////////////////////////////////
assign i_type={{20{instr_in[24]}},instr_in[24:13]};//→ For I-type (sign-extended 12-bit immediate).
assign s_type={{20{instr_in[24]}},instr_in[24:18],instr_in[4:0]};//→ For S-type (split across [31:25] and [11:7]).
assign b_type={{20{instr_in[24]}},instr_in[0],instr_in[23:18],instr_in[4:1],1'b0};//→ For B-type branches (uses bits in rearranged positions with LSB = 0).
assign u_type={instr_in[24:5],12'h000};//→ For U-type (upper 20 bits shifted left by 12).
assign j_type={{12{instr_in[24]}},instr_in[12:5],instr_in[13],instr_in[23:14],1'b0};//→ For J-type jumps (similar to B-type but different format).
assign csr_type={27'b0,instr_in[12:8]};//→ For CSR-type instructions (immediate = rs1[4:0], zero-extended).
///////////////////////////////////////////////////////////////////////////
always@(*)begin
        case(imm_type)
        3'b000:begin
               imm_out= i_type; //→ No immediate used in R-type instructions.
        end
        3'b001:begin
               imm_out=i_type;
        end
        3'b010:begin
               imm_out=s_type;
        end
        3'b011:begin
               imm_out=b_type;
        end
          3'b100:begin
               imm_out=u_type;
        end
        3'b101:begin
               imm_out=j_type;
        end
        3'b110:begin
               imm_out=csr_type;
        end
        3'b111:begin
               imm_out=i_type;
        end
        default:begin
                imm_out=i_type;
        end
        
        endcase
end
endmodule
