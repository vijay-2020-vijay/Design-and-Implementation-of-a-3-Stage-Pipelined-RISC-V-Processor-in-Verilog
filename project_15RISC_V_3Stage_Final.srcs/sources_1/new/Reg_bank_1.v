
///•	Acts as a clocked 32-bit PC register holding the current instruction 
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//This module stores and updates the current Program Counter (PC) value in a clocked register.
//It acts as a synchronous PC register used in RISC-V pipeline to hold the address of the current instruction.

module Reg_bank_1(
input[31:0]PC_mux_in,//coming from the msrv32_pc_mux//
input ms_riscv32_clk,//coming from the top module//
input ms_riscv32_rst,//coming from the top module //
output reg[31:0]pc_out//it goes to these following modules: reg_block2(),immediate_adder(),pc_mux(goes to pc_in  point)//
);

always@(posedge ms_riscv32_clk )begin
     if(ms_riscv32_rst==1'b1)begin
         pc_out<=32'h0000_0200;///Boot address//32'h80000000
     end
     else begin
         pc_out<=PC_mux_in;
     end
end
endmodule
/////✅ Summary:
///•	On reset → PC is set to boot address.
///•	On every clock cycle → PC is updated from pc_max_in.
