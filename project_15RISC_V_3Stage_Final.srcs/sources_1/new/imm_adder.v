`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//The msrv32_immediate_adder computes an effective address by adding an immediate value to either the PC or rs1 register value, depending on a control signal.
 //This effective address is used for:
//•	Branch target computation
//•	Load/store address calculation
//•	Jump address generation
///////////////////////////////////////////////////////////////////////////////////
module imm_adder(
input[31:0]pc_in,//coming from reg_block1//•	32-bit input carrying the Program Counter (PC) value.
//•	Used when addressing is PC-relative (e.g., auipc, jal, branches).//
input[31:0]rs_1_in,//value of the [rs1]//coming from the integer file//•	Used when addressing is base+offset (e.g., lw, sw).
input iadder_src_in,///this is control pin besically defines which value should be passes further it will be added by the immediate value
//•	Comes from the control unit or decoder.
input[31:0]imm_in,//comming from immediate_generetor block//used to measured the effective address//This will be added to either pc_in or rs_1_in. 
output reg[31:0]iadder_out/// resultent effective address value after adding immediate value ///this value should be sent to the 1.reg_block2 2.[31:1] to pc_mux
/// store unit,[1:0]bit to decoder.//[31:1] → sent to pc_mux for control flow//1:0] → sent to the decoder for address alignment/misalignment detection
);
wire[31:0]next_address;
assign next_address=iadder_src_in?rs_1_in:pc_in;
always@(*)begin
         iadder_out=next_address+imm_in;
end
endmodule
