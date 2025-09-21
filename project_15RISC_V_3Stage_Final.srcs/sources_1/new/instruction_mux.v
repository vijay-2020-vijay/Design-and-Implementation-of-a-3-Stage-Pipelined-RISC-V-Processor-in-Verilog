`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//? Purpose of the Module:
//This module is responsible for parsing the 32-bit RISC-V instruction into individual fields like opcode, funct3, funct7, rs1, rs2, rd, and csr address.
//It also includes flush logic, which replaces the instruction with a NOP (addi x0, x0, 0) when flushing is needed due to branch misprediction or pipeline hazard.

module instruction_mux(
input flush_in,//this is the control signal coming from mechine control//
input[31:0]ms_riscv32_mp_instr_in,//contains the instraction code coming from (ms_riscv32_mp_instr_in)
output reg[6:0]opcode_out,//[6:2] portion of opcode goes to (the branch unit) and (mechine control)
output reg[2:0]funct3_out,//[1:0] goes to (store unit) and branch unit and decoder 
output reg[6:0]funct7_out,//(also goes to decoder and mechine control)
output reg[4:0]rs1addr_out,//to integer file and mechine control
output reg[4:0]rs2addr_out,//to integer file and mechine control
output reg[4:0]rdaddr_out,//to integer file and mechine control
output reg[11:0]csr_addr_out,//address of the csr to read/write/modify and send to it reg_block_2
output reg[31:7]instr_out//connected to immediate_generetor(goes to immediate_generetor)
);

wire[31:0]instr_mux,flush_address;
assign flush_address=32'h00000013;///this is not a actuall adress
assign instr_mux=flush_in?flush_address:ms_riscv32_mp_instr_in;
always@(*)begin
        opcode_out=instr_mux[6:0];
        funct3_out=instr_mux[14:12]; 
        funct7_out=instr_mux[31:25];
        rs1addr_out=instr_mux[19:15];
        rs2addr_out=instr_mux[24:20];
        rdaddr_out=instr_mux[11:7];
        csr_addr_out=instr_mux[31:20];
        instr_out=instr_mux[31:7];
end
endmodule








////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

