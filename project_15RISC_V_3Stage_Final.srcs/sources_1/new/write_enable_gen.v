`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
///✅ Purpose:
//This module controls whether write operations are allowed to:
//•	The integer register file
//•	The CSR (Control and Status Register) file
//It ensures that no write occurs when a pipeline flush is issued (such as due to branch misprediction or exception).
///////////////////////////////////////////////////////////////////////////////////


module write_enable_gen(
input flush_in,//flushes the output when it is activited or set high(comming from the mechine control)
//Flush signal, usually activated due to control hazards or exceptions.
input rf_wr_en_reg_in,//register file write enable pipelined output(comming from the Register block 2)
input csr_wr_en_reg_in,//control status register write enable pipelined output(this is also comming from the register block 2)
output reg wr_en_integer_file_out,//write enable integer file output goes to (integer file)
output reg wr_en_csr_file_out//write enable csr file ,also goes to the csr file
);
always@(*)begin
      if(flush_in==1'b1) begin
          wr_en_integer_file_out=1'b0;
          wr_en_csr_file_out=1'b0;
      end
      else begin
         wr_en_integer_file_out=rf_wr_en_reg_in;
         wr_en_csr_file_out=csr_wr_en_reg_in;
      end
end
endmodule
/////////////////////////
//✅ Final Summary:
//This module acts as a conditional gatekeeper for register file write permissions:
//•	Ensures no invalid writes during flushes
//•	Passes through the registered write enable signals during normal operation
//•	Protects architectural state consistency in a pipelined RISC-V processor