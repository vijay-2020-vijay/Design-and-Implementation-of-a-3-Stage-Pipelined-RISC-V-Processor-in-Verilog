`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
/////The msrv32_machine_control module is the heart of the trap and interrupt handling mechanism for a RISC-V-based microprocessor (msrv32).
 //It's designed as a Finite State Machine (FSM) with defined states and handles both exceptions (like illegal instructions or
 // misaligned accesses) and interrupts (external, timer, software). Here's the complete functional breakdown of each part of your design:
 // 1. Purpos
 //This module manages:
//	Exception detection and classification (e.g., illegal instructions, misaligned accesses).
//	Interrupt detection (based on RISC-V privilege specification).
//	Trap control: updating trap-related CSRs (mepc, mcause, etc.).
//	FSM to control processor state transitions.
//	Flush and PC redirection via pc_src_out.
////////////////////////////////////////////////////////////////////////////////////
 
 
module machine_control(
input ms_riscv32_mp_clk_in,//clock input
input ms_riscv32_mp_rst_in,//reset input
input ms_riscv32_mp_eirq_in,//external interrupt reqest(to csr)
input ms_riscv32_mp_tirq_in,//timmer intrupt request (to csr)
input ms_riscv32_mp_sirq_in,// software intrrupt request(to csr)
input illegal_instr_in, //set when an  invalid/unimplemented instraction is featched(coming from decoder)
input misaligned_load_in,// set when a load is misaligned(violets memorey alignment rule)(from decoder)
input misaligned_store_in,//set when a store is misaligned(from decoder)
input misaligned_instr_in,//set when instraction featch adress is mis aligned(from decoder)
input[4:0]opcode_6_to_2_in,//opcode field(bits[6:2]) (from instraction(from instraction mux)
input[2:0]funct3_in,//(from instraction mux)
input[6:0]funct7_in,//(from instraction mux)
input[4:0] rs1_addr_in,//(from instraction mux)
input[4:0] rs2_addr_in,//(from instraction mux)
input[4:0] rd_addr_in,//(from instraction mux)
output reg i_or_e_out,//intrrupt or exception.when set high indicates an intrrupt ortherwise indicates exception.
//used to update the most significant bit of mcause register//
output reg [3:0]cause_out,//contains the exception code.//used to update the most significant bit of mcause register
output reg instret_inc_out,//sets high enables the instraction retired counting(to csr)
output reg  mie_clear_out,// sets the mie bit of mstatus zero(which globally disables intrrupts).the old value of mie is saved in the mstatus mpie field.
output reg mie_set_out,//when set high sets the MPIE bit of mstatus to one. the old value of MPIE is saved in the mstatus MIE field(to CSR)
output reg misaligned_expectetion_out,//signals for misaligned access exception
output reg set_epc_out,//updates the mepc register with the value pc.(to csr)
output reg set_cause_out,//contains the exception code.used to update the mcause register(to csr)
output reg flush_out,//flushes the pipelined when set
output reg trap_taken_out,//when set high indicates that a trap will be taken in the next clock cycle
output reg[1:0] pc_src_out,//selects the program counter sources(PC MUX)
input meie_in,//current value of MEIE bit of mstatus CSR(from CSR)//mie_in, meie_in, mtie_in, msie_in	M-mode interrupt enable bits
input mtie_in,//current value of MTIE bit of mie CSR(from CSR)//mie_in, meie_in, mtie_in, msie_in	M-mode interrupt enable bits
input msie_in,//current value of MSIE bit of mie CSR(from CSR)//mie_in, meie_in, mtie_in, msie_in	M-mode interrupt enable bits
input meip_in,//current value of MEIP bit of mip CSR(from CSR)//M-mode interrupt pending bits
input mtip_in,//current value of MTIP bit of mip CSR(from CSR)//M-mode interrupt pending bits
input msip_in//current value of MSIP bit of mip CSR(from CSR)//M-mode interrupt pending bits
/////////total number of inputs 22////////////////////////////////////////////////////////////////////////////////////////////////


); 
///////////////total number of outputs are 11///////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////formetion of the internal control logic//////////////////
wire exception;
wire ip;
wire eip;
wire tip;
wire sip;
wire is_system;
wire rs1_addr_zero;
wire rs2_addr_zero;
wire rd_zero;
wire rs2_addr_mret;
wire rs2_addr_ebreak;
wire funct3_zero;
wire funct7_zero;
wire funct7_mret;
wire csr;
wire reg_pre_instret_in;
wire ecall;
wire ebreak_mret;
wire mret;
wire ebreak;

assign funct7_mret=(funct7_in==7'b0011000)?1:0;
assign is_system=(opcode_6_to_2_in==5'b11100)?1:0;
assign funct3_zero=(funct3_in==3'b000)?1:0;
assign funct7_zero=(funct7_in==7'd0)?1:0;
assign rs1_addr_zero=(rs1_addr_in==5'd0)?1:0;
assign rs2_addr_zero=(rs2_addr_in==5'd0)?1:0;
assign rd_zero=(rd_addr_in==5'd0)?1:0;
assign rs2_addr_mret=(rs2_addr_in==5'd2)?1:0;
assign rs2_addr_ebreak=(rs2_addr_in==5'd1)?1:0;
assign eip=meie_in & (meip_in |  ms_riscv32_mp_eirq_in);
assign tip=mtie_in & (mtip_in |  ms_riscv32_mp_tirq_in);
assign sip=msie_in & (msip_in  | ms_riscv32_mp_sirq_in );
assign ip=eip|sip|tip;
assign exception= illegal_instr_in | misaligned_instr_in | misaligned_load_in | misaligned_store_in;
assign mret=(is_system & funct7_mret & rs2_addr_mret & rs1_addr_zero &  funct3_zero );
assign ecall=(is_system &  rs1_addr_zero & funct3_zero &  rd_zero & funct7_zero & rs2_addr_zero);
assign ebreak=(is_system & rs1_addr_zero & funct3_zero &  rd_zero & funct7_zero & rs2_addr_ebreak);
wire mie_in;
assign mie_in=1;
///////////////////////complete internal control logic//////////////////////////////////////////////////////////////////////////////////////////// 
always@(*)begin
     if((mie_in & ip) | (exception | ecall | ebreak))begin
        trap_taken_out=1'b1;
     end
     else begin
        trap_taken_out=1'b0;
     end
end

 parameter STATE_RESET = 2'b00;//s0
 parameter STATE_OPERATING   = 2'b01;//s1
 parameter STATE_TRAP_TAKEN  = 2'b10;//s2
 parameter STATE_TRAP_RETURN = 2'b11;//s3
 reg[1:0] state_t,curr_state,next_state;
 ///////////////// FSM State Register//////////////////////////////////////////////////////////////
    always @(posedge ms_riscv32_mp_clk_in) begin
        if( ms_riscv32_mp_rst_in)begin
            curr_state <= STATE_RESET;
        end   
       else begin
            curr_state <= next_state;
       end      
    end
//////////////////FSM Next State Logic///////////////////////////////////////////////////////////////////
always @(*) begin
    //next_state = curr_state;
    case (curr_state)
        STATE_RESET: begin
                next_state = STATE_OPERATING;
        end
        STATE_OPERATING: begin
            if (trap_taken_out)          
                next_state = STATE_TRAP_TAKEN;
            else if (mret)// Use CSR mret instruction detection input
                next_state = STATE_TRAP_RETURN;
            else
                next_state = STATE_OPERATING;
        end
        STATE_TRAP_TAKEN: begin
            next_state = STATE_OPERATING; // After setting EPC, CAUSE, etc., move to operating
        end
        STATE_TRAP_RETURN: begin
            next_state = STATE_OPERATING;  // After restoring state, move to operating
        end
        default: begin
            next_state = STATE_OPERATING;
        end
    endcase
end
//////////////// Misaligned Exception Flag///////////////////////////////////////////////////////////////////
 
    always @(posedge ms_riscv32_mp_clk_in ) begin
        if (ms_riscv32_mp_rst_in)
             misaligned_expectetion_out <= 1'b0;
        else
            misaligned_expectetion_out<= misaligned_instr_in || misaligned_load_in || misaligned_store_in;
    end
/////////////  // Output Logic///////////////////////////////////////////////////////////////////////////////////
    always @(*) begin
        case (curr_state)
//////////////////////////////////////////////////////////////////////////////////////////////
//safely flush the pipelineing //prevent the instraction retirement//cler trap releated flag//hold pc_src stable//avoiding triggering CSR writes 
//or interrupt behavior        
            STATE_RESET: begin
                pc_src_out=2'b00;//selects pc source as defult/reset values(typically pc reset vector is used)
                instret_inc_out=1'b0;//do not increment istraction-retired counter during reset
                //trap_taken_out=1'b0;//no trap should be taken during reset
                flush_out=1'b1;//assert flush to invalidate any garbage in the pipelineing
                set_epc_out=1'b0;///not need to record the current pc in mepc because no trap is occurring
                set_cause_out=1'b0;////no cause(i.e no exception,or interrup) to record in mcause
                mie_clear_out=1'b0;//do not change the interrupt enable status.it was already handled during trap entry or trap return
                mie_set_out=1'b0;////again, no change to interrupt_enable state(this is only set during mret(trap return))
                //misaligned_expectetion_out=1'b0;//there is no  misaligned happening during normal execution.if it did the fsm would go to state_trap_entrey
                cause_out=4'b0000;//in "state operating" region , since there is no trap no exception, there is no cause to report
                //so cause_out is held to zero in default condition
                i_or_e_out=1'b0;//no interrupt or exceptionb occurred. this signal only matters when a trap is taken.
                 
            end
///////////////////////////////////////////////////////////////////////////////////////
///this is the normal execution state of the processor.when no trup ,no interrupt,no exception is occureing,and the processor is executing valid instractions
            STATE_OPERATING: begin
                pc_src_out=2'b11;//because of pc+4 next sequentional instraction//no exception//no interrupt // no trap // no mret
                //it is default pc update path in a normal pipelineing(non branching, non jump,non exception)
                flush_out= 1'b0;//no flushing is required//flush is required when pipelineing system should be cleared(trap,interrupt,mret,branch misprediction)
                instret_inc_out=1'b1;//increments the retired instraction counter(minstret) for every instraction//this is set unconditionally to 1,
                ///meaning all instractions(even illegal ones)are counted
                //trap_taken_out=1'b0;//no trap or interrupt is being handled in this state.execution is progressing normally
                set_epc_out=1'b0;//not need to record the current pc in mepc because no trap is occurring
                set_cause_out=1'b0;//no cause(i.e no exception,or interrup) to record in mcause,since the execution is normal
                mie_clear_out=1'b0;//do not change the interrupt enable status.it was already handled during trap entry or trap return
                mie_set_out=1'b1;//again, no change to interrupt_enable state(this is only set during mret(trap return))
                //misaligned_expectetion_out=1'b0;//there is no  misaligned happening during normal execution.if it did the fsm would go to state_trap_entrey
            if (eip) begin
                cause_out  = 4'b1011;
                i_or_e_out= 1'b1;
            end

            else if (sip) begin
                 cause_out  = 4'b0011;
                i_or_e_out = 1'b1;
            end
            else if (tip) begin
                cause_out  = 4'b0111;
                i_or_e_out = 1'b1;
            end
            else if (illegal_instr_in) begin
                cause_out  = 4'b0010;
                i_or_e_out = 1'b0;
            end
            else if (misaligned_instr_in) begin
                cause_out  = 4'b0000;
                i_or_e_out = 1'b0;
            end
            else if (ecall) begin
                // ecall
                cause_out  = 4'b1011;
                i_or_e_out = 1'b0;
            end
            else if (ebreak) begin
                // ebreak
                cause_out  = 4'b0011;
                i_or_e_out = 1'b0;
            end
            else if (misaligned_store_in) begin
                cause_out  = 4'b0110;
                i_or_e_out = 1'b0;
            end
            else if (misaligned_load_in) begin
                cause_out  = 4'b0100;
                i_or_e_out = 1'b0;
            end
            end

            STATE_TRAP_TAKEN: begin
                pc_src_out    = 2'b10;//pc should be set to:mtvec(machine trap vector)//selects mtvec as the next PC(trap handler entry)
               // trap_taken_out=1'b1;// indicates that a trap is being taken( used by csr and pipelined flush)
                instret_inc_out=1'b0;//no increment to instraction retired counter(instret)
                flush_out     = 1'b1;//pipelineing flush required due to control transfer to trap handler(mtvec)
                set_epc_out   = 1'b1;//set mepc to the faulting instraction address
                set_cause_out = 1'b1;//set mcause to the trap/interrupt cause
                mie_clear_out = 1'b1;//cler mie(disable interrupts) as part of trap entry(mie =0)
                mie_set_out=1'b0;//trap is being taken so mie must be cleared,not set ,set only on mret
               // misaligned_expectetion_out=1'b0;// the misaligned exception was detected earlier, so it is not flagged here
                 // cause_out=4'b0000;
               //   i_or_e_out=1'b0;
            end
            STATE_TRAP_RETURN: begin
                pc_src_out    = 2'b01;//pc is updated from mepc,which holds the return address
                flush_out     = 1'b1;// flesh the pipeline//clears partially execuated instractions
                instret_inc_out=1'b0;//instraction retirement is paused;mret itself does not increment
               // trap_taken_out=1'b0;//not trap we are returning from the trap
                set_epc_out=1'b0;//do not set EPC now//it was already saved when the trap occurred
                set_cause_out=1'b0;//do not set cause //we are not in a new trap
                mie_clear_out=1'b0;// no need to clear mie;it is cleared during trap entry
                mie_set_out=1'b1;//Re_enables interrupts (by setting mie bit(from mstatus))
                //cause_out=4'b0000;// no cause to reporet //not trap//not interrupt
               // misaligned_expectetion_out=1'b0;//no misaligned issue here
                //i_or_e_out=1'b0;// not an interrupt or exception now
            end
        endcase
    end
endmodule