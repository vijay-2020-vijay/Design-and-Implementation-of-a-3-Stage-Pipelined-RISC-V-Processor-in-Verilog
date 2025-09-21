`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//The module msrv32_wb_mux_sel_unit is a Write-Back MUX Selector Unit in a RISC-V processor pipeline. It determines:
//What value is written back to the integer register file (e.g., x0-x31).
//What is fed as the second operand to the ALU (either an immediate value or a register value).
///////////////////////////////////////////////////////////////////////////////////
module wb_mux_sel_unit(
input alu_src_reg_in,//usd to select rs2 register data and the immediate data(comming from reg_block_2)//
input[2:0]wb_mux_sel_reg_in,//slects the data to be written to the integer file(coming from the reg_block_2)//
input[31:0]alu_result_in,////the result produced by the alu(comming from alu)
input[31:0]lu_output_in,//output of the load unit(coming from the load section)
input[31:0]imm_reg_in,//immediate data(from reg_block_2)
input[31:0]iadder_out_reg_in,//the sum of the immediate data or rs1 or pc (comming from reg_block also)
input[31:0]csr_data_in,//data output port of csr module (comming from the the csr file)
input[31:0]pc_plus_4_reg_in,//pc+4(from reg_blocl_2)
input[31:0]rs2_reg_in,//rs2 register output (comming also reg_block_2)
output reg[31:0]wb_mux_out,//the output of the WB_mux(goes to integer file) thisa value will be selected by (wb_mux_sel_reg_in) this 3bit input pins
output [31:0]alu_2nd_src_mux_out///this data will also selected by  alu_src_reg_in//to alu
);

assign alu_2nd_src_mux_out=(alu_src_reg_in==1'b1)? rs2_reg_in:imm_reg_in;
always@(*)begin
        case(wb_mux_sel_reg_in)
        3'd0:begin
            wb_mux_out=alu_result_in;//(r_tye and I_type instraction the result should be stored in destinetion register)
        end
        3'd1:begin
            wb_mux_out=lu_output_in;//(load unit)
        end
        3'd2:begin
            wb_mux_out=imm_reg_in;//(lui immediate value)
        end
        3'd3:begin
            wb_mux_out=iadder_out_reg_in;//(AUIPC(RSI+IMM/PC+IMM)))
        end
        3'd4:begin
             wb_mux_out=csr_data_in;//csr
        end
        3'd5:begin
             wb_mux_out=pc_plus_4_reg_in;//(for jal and jalr)
        end
        default:begin
             wb_mux_out=alu_result_in;
        end
        endcase
end

endmodule

// Summary
//	ALU Input Selector: Decides if ALU uses rs2 or imm.
//	Write-Back MUX: Routes final result (ALU, memory, PC+4, CSR, imm, etc.) to register file.
//	Central to proper functioning of the Write Back stage in a pipelined RISC-V CPU.



