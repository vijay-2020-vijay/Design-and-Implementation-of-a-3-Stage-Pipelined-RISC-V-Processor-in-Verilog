`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
module RISCV_32I_TOP(
    //---------------- Clock and Reset ----------------//
    input  ms_riscv32_mp_clk_in,           // System clock input
    input  ms_riscv32_mp_rst_in,           // System reset input (active high, async)

    //---------------- Instruction Interface ----------------//
    input  ms_riscv32_mp_instr_hready_in,  // Instruction memory ready signal (from AHB)
    input  [31:0] ms_riscv32_mp_instr_in,  // Instruction data fetched from instruction memory

    //---------------- Data Memory Interface ----------------//
    input  [31:0] ms_riscv32_mp_dmdata_in,     // Data read from memory (LOAD instruction)
    output       ms_riscv32_mp_dmwr_req_out,   // Write request signal (STORE operation)
    output [31:0] ms_riscv32_mp_dmaddr_out,    // Data memory address (for LOAD/STORE)
    output [31:0] ms_riscv32_mp_dmdata_out,    // Data to write to memory (STORE)
    output [3:0]  ms_riscv32_mp_dmwr_mask_out, // Byte mask to enable per-byte write (STORE)
    output [1:0]  ms_riscv32_mp_data_htrans_out, // AHB transfer type for data memory (IDLE, NONSEQ, etc.)

    //---------------- Control & Response Signals ----------------//
    input        ms_riscv32_mp_hresp_in,       // AHB response signal (0: OKAY, 1: ERROR)
    input [63:0] ms_riscv32_mp_rc_in,          // Read complete / handshake or return code (typically from memory)
    input        ms_riscv32_mp_hready_in,      // AHB data memory ready (signals end of data phase)

    //---------------- Interrupt Inputs ----------------//
    input        ms_riscv32_mp_eirq_in,        // External interrupt request (machine mode)
    input        ms_riscv32_mp_tirq_in,        // Timer interrupt request (machine mode)
    input        ms_riscv32_mp_sirq_in,        // Software interrupt request (machine mode)

    //---------------- Address Output ----------------//
    output [31:0] ms_riscv32_mp_iadder_out ,    // Instruction address (i.e., PC output to fetch next instruction)
    output [31:0]pc_mux_out_risc
    );
 ///////////////////////////////////////////STAGE_1/////////////////////////////////////////////////
    // input wires to PC_MUX
    wire [31:0]  csr_epc_out,csr_trap_address_out;
    //Output wires of PC_MUX
  
    wire branch_taken_out;
    wire [1:0] mc_pc_src_out;


/////output wires of pc_mux/////////////////////////////////    
    wire [31:0]pc_pc_plus_4_out;  
    wire pc_misaligned_instr_out;
    wire[31:0]pc_pc_mux_out;
/////output wires of reg_block1/////////////////////////////////       
    wire [31:0] rgb1_pc_out;
/////output wires of instraction_mux/////////////////////////////////  
    wire [6:0] instr_mux_opcode_out;
    wire [2:0] instr_mux_funct3_out;
    wire [6:0] instr_mux_funct7_out;
    wire [4:0] instr_mux_rs1addr_out;
    wire [4:0] instr_mux_rs2addr_out;
    wire [4:0] instr_mux_rdaddr_out;
    wire [11:0] instr_mux_csr_addr_out;
    wire [31:7] instr_mux_instr_out;      
 /////output wires of immediate generetor///////////////////////////////// 
    wire [31:0] imm_gen_out;
 /////output wires of immediate adder/////////////////////////////////////
    wire[31:0]iadder_imm_out;
 
 
 
 //////////////////////////////////////////////////////////////////////////////////////////////////////////////////   
pc pc11 (
    .rst_in(ms_riscv32_mp_rst_in),                   // Reset input to initialize or restart the PC
    .pc_src_in(mc_pc_src_out),                       // Selects source for the next PC (normal, trap, EPC, etc.)
    .pc_in(rgb1_pc_out),                             // Current PC from register block (for normal PC update)
    .epc_in(csr_epc_out),                            // EPC value for returning from exception
    .trap_address_in(csr_trap_address_out),          // Trap vector address to handle exceptions/interrupts
    .branch_taken_in(branch_taken_out),              // Branch decision signal from branch unit
    .iadder_in(iadder_imm_out[31:1]),                        // Address from immediate adder for branching or jumping
    .ahb_ready_in(ms_riscv32_mp_hready_in),          // Memory interface ready signal (AHB bus readiness)
    
    .iadder_out(ms_riscv32_mp_iadder_out),           // Final PC value sent to instruction memory
    .pc_plus_4_out(pc_pc_plus_4_out),             // PC + 4 value used for storing return address
    .misaligned_instr_logic_out(pc_misaligned_instr_out), // Flag for detecting misaligned instruction access
    .pc_max_out(pc_pc_mux_out)                          // Final PC value used internally for debug/misalignment
);
////////////////////reg_block_1//////////////////////////////////////////////////////////////////////////
assign pc_mux_out_risc =pc_pc_mux_out; 
///////////////////////////////////////////////////////////////////////////////////////////////////////
Reg_bank_1 rgb1 (
    .PC_mux_in(pc_pc_mux_out),            // Instruction address selected by PC multiplexer (from msrv32_pc_mux)
    .ms_riscv32_clk(ms_riscv32_mp_clk_in),  // System clock signal (from top module)
    .ms_riscv32_rst(ms_riscv32_mp_rst_in),  // System reset signal (from top module)
    .pc_out(rgb1_pc_out)               // Program counter output → goes to: reg_block2, immediate_adder, and pc_mux
);
///////////////////////////////////////////////STAGE_2/////////////////////////////////////////////////
////////instruction_mux///////////////////////////////////////////////////////////////////////////////
wire mc_flush_out;  
instruction_mux im1 (
    .flush_in(mc_flush_out),                  // Control signal from machine control for flushing instruction
    .ms_riscv32_mp_instr_in(ms_riscv32_mp_instr_in), // 32-bit instruction input from ms_riscv32_mp_instr
    .opcode_out(instr_mux_opcode_out),        // Opcode [6:2] to branch unit and machine control
    .funct3_out(instr_mux_funct3_out),        // Funct3 to store unit, branch unit, and decoder
    .funct7_out(instr_mux_funct7_out),        // Funct7 to decoder and machine control
    .rs1addr_out(instr_mux_rs1addr_out),      // Source register 1 address to integer file and machine control
    .rs2addr_out(instr_mux_rs2addr_out),      // Source register 2 address to integer file and machine control
    .rdaddr_out(instr_mux_rdaddr_out),        // Destination register address to integer file and machine control
    .csr_addr_out(instr_mux_csr_addr_out),    // CSR address to reg_block_2 for CSR access
    .instr_out(instr_mux_instr_out)           // Instruction bits [31:7] to immediate generator
);                        
///////Imm_generator//////////////////////////////////////////////////////
  wire [2:0] decoder_imm_type_out;
      imm_generetor img1 (
     .instr_in(instr_mux_instr_out),     // 25-bit instruction field [31:7] → from instruction_mux
     .imm_type(decoder_imm_type_out),    // 3-bit control signal indicating immediate type → from decoder
     .imm_out(imm_gen_out)               // Final 32-bit immediate value → to Register_block_2 and immediate_adder
 );

/////////Imm_adder///////////////////////////////////////////////////////
  wire [31:0] interger_file_rs1_out;
  wire decoder_iadder_src_out;
  imm_adder ima1 (
    .pc_in(rgb1_pc_out),                  // Program Counter from reg_block1
    .rs_1_in(interger_file_rs1_out),      // Source register rs1 value from integer file
    .iadder_src_in(decoder_iadder_src_out), // Select between PC and rs1
    .imm_in(imm_gen_out),                 // Immediate value from immediate generator
    .iadder_out(iadder_imm_out)           // Output effective address
);
 //////Branch_unit/////////////////////////////////////////////////////
  wire [31:0] interger_file_rs2_out;
  wire [4:0] instr_mux_6_to_2_opcode; 
  assign instr_mux_6_to_2_opcode = instr_mux_opcode_out [6:2];
branch_unit bu1 (
    .rs1_in(interger_file_rs1_out),           // Source register 1 value
    .rs2_in(interger_file_rs2_out),           // Source register 2 value
    .opcode_6_to_2_in(instr_mux_6_to_2_opcode), // Opcode bits [6:2] from instruction
    .funct3_in(instr_mux_funct3_out),         // Funct3 field
    .branch_taken_out(branch_taken_out)       // Branch decision output
);

  ////// Integer_File ///////
  wire [4:0] rgb2_rd_addr_reg_out;
  wire [31:0] wb_mux_sel_rd_in;
  wire wr_en_block_integer_file_out;
  msrv32_integer_file if1 (
    .ms_riscv_32_mp_clk_in(ms_riscv32_mp_clk_in),      // Clock input
    .ms_riscv_32_mp_rst_in(ms_riscv32_mp_rst_in),      // Reset input
    .rs_2_addr_in(instr_mux_rs2addr_out),              // Source register 2 address
    .rd_addr_in(rgb2_rd_addr_reg_out),                 // Destination register address
    .wr_en_in(wr_en_block_integer_file_out),           // Write enable
    .rd_in(wb_mux_sel_rd_in),                          // Write data from WB mux
    .rs_1_addr_in(instr_mux_rs1addr_out),              // Source register 1 address
    .rs_1_out(interger_file_rs1_out),                  // Output of rs1
    .rs_2_out(interger_file_rs2_out)                   // Output of rs2
);

                            
 /////////// wr_en_generator/////////////////////////////////////////////////
  wire wr_en_gen_csr_file_wr_en_out;
  wire rgb2_rf_wr_en_reg_out, rgb2_csr_wr_en_reg_out;
write_enable_gen weg1 (
    .flush_in(mc_flush_out),                     // Flush signal from machine control
    .rf_wr_en_reg_in(rgb2_rf_wr_en_reg_out),     // Register file write enable from reg_block2
    .csr_wr_en_reg_in(rgb2_csr_wr_en_reg_out),   // CSR write enable from reg_block2
    .wr_en_integer_file_out(wr_en_block_integer_file_out), // Final write enable to integer file
    .wr_en_csr_file_out(wr_en_gen_csr_file_wr_en_out)      // Final write enable to CSR file
);
  
  ///// Decoder //////////////////  /////////////////////////////////////
  wire mc_trap_taken_out;
  wire funt7_5_decoder_in;
  wire [1:0] iadder_decoder_out;
  wire  decoder_load_unsigned_out, decoder_alu_src_out,decoder_csr_wr_en_out,decoder_rf_wr_en_out,decoder_illegal_instr_out;
  wire decoder_misaligned_load_out,decoder_misaligned_store_out,decoder_mem_req_out,decoder_is_load,decoder_is_store;
  wire [2:0] decoder_csr_op_out,decoder_wb_mux_sel_out;
  wire [1:0] decoder_load_size_out;
  wire [3:0] decoder_alu_opcode_out;
  assign iadder_decoder_out = iadder_imm_out[1:0];
  assign funt7_5_decoder_in = instr_mux_funct7_out[5];  
msrv32_decoder md1 (
    .trap_taken_in(mc_trap_taken_out),             // Trap occurred → from machine control
    .funct7_5_in(funt7_5_decoder_in),               // Bit 5 of funct7 field → helps distinguish ADD/SUB
    .opcode_in(instr_mux_opcode_out),              // Opcode field [6:0] → determines instruction type
    .funct3_in(instr_mux_funct3_out),              // Funct3 field → sub-operation like LW, LH, LB
    .iadder_out_1_to_0_in(iadder_decoder_out),     // Address bits [1:0] → check for alignment errors

    .wb_mux_sel_out(decoder_wb_mux_sel_out),       // Writeback MUX selector → to Register block 2
    .imm_type_out(decoder_imm_type_out),           // Immediate type selector → to immediate generator
    .csr_op_out(decoder_csr_op_out),               // CSR operation selector → to Register block 2
    .mem_wr_req_out(decoder_mem_req_out),          // Memory write request signal → to store unit
    .alu_opcode_out(decoder_alu_opcode_out),       // ALU operation code → to Register block 2
    .load_size_out(decoder_load_size_out),         // Size of load (byte/halfword/word) → to Register block 2
    .load_unsigned_out(decoder_load_unsigned_out), // Unsigned load indicator → to Register block 2
    .alu_src_out(decoder_alu_src_out),             // ALU source select (0: rs2, 1: imm) → to Register block 2
    .iadder_src_out(decoder_iadder_src_out),       // I-ADDR source select (0: PC, 1: rs1) → to immediate adder
    .csr_wr_en_out(decoder_csr_wr_en_out),         // CSR write enable → to Register block 2 and CSR file
    .rf_wr_en_out(decoder_rf_wr_en_out),           // Register file write enable → to Register block 2
    .illegal_instr_out(decoder_illegal_instr_out), // Illegal instruction flag → to machine control
    .misaligned_load_out(decoder_misaligned_load_out),   // Load misalignment flag → to machine control
    .misaligned_store_out(decoder_misaligned_store_out), // Store misalignment flag → to machine control
    .is_load_out(decoder_is_load),                 // Load instruction type flag
    .is_store_out(decoder_is_store)                // Store instruction type flag
);
        
        
                    
 /////////Machine_control_unit////////////
  wire csr_meie_out,csr_mtie_out,csr_msie_out,csr_meip_out,csr_mtip_out,csr_msip_out;
  wire mc_i_or_e_out,mc_instret_inc_out,mc_mie_clear_out,mc_mie_set_out,mc_misaligned_exception_out,mc_set_epc_out ; 
  wire mc_set_cause_out;
  wire [3:0] mc_cause_out; 
  machine_control mc1 (
    .ms_riscv32_mp_clk_in(ms_riscv32_mp_clk_in),          // Clock input
    .ms_riscv32_mp_rst_in(ms_riscv32_mp_rst_in),          // Reset input
    .ms_riscv32_mp_eirq_in(ms_riscv32_mp_eirq_in),        // External interrupt request
    .ms_riscv32_mp_tirq_in(ms_riscv32_mp_tirq_in),        // Timer interrupt request
    .ms_riscv32_mp_sirq_in(ms_riscv32_mp_sirq_in),        // Software interrupt request
    .illegal_instr_in(decoder_illegal_instr_out),         // Illegal instruction signal from decoder
    .misaligned_load_in(decoder_misaligned_load_out),     // Misaligned load from decoder
    .misaligned_store_in(decoder_misaligned_store_out),   // Misaligned store from decoder
    .misaligned_instr_in(pc_misaligned_instr_out),// Misaligned instruction fetch address
    .opcode_6_to_2_in(instr_mux_6_to_2_opcode),           // Opcode[6:2] from instruction_mux
    .funct3_in(instr_mux_funct3_out),                     // funct3 from instruction_mux
    .funct7_in(instr_mux_funct7_out),                     // funct7 from instruction_mux
    .rs1_addr_in(instr_mux_rs1addr_out),                  // rs1 address from instruction_mux
    .rs2_addr_in(instr_mux_rs2addr_out),                  // rs2 address from instruction_mux
    .rd_addr_in(instr_mux_rdaddr_out),                    // rd address from instruction_mux
    .i_or_e_out(mc_i_or_e_out),                           // Exception or interrupt type output
    .cause_out(mc_cause_out),                             // Cause code output
    .instret_inc_out(mc_instret_inc_out),                 // Instruction retired flag
    .mie_clear_out(mc_mie_clear_out),                     // Clear MIE bit
    .mie_set_out(mc_mie_set_out),                         // Set MPIE bit
    .misaligned_expectetion_out(mc_misaligned_exception_out), // Misaligned access exception
    .set_epc_out(mc_set_epc_out),                         // Set EPC signal
    .set_cause_out(mc_set_cause_out),                     // Set CAUSE signal
    .flush_out(mc_flush_out),                             // Pipeline flush signal
    .trap_taken_out(mc_trap_taken_out),                   // Trap trigger signal
    .pc_src_out(mc_pc_src_out),                           // PC MUX selector
    .meie_in(csr_meie_out),                               // MEIE from CSR
    .mtie_in(csr_mtie_out),                               // MTIE from CSR
    .msie_in(csr_msie_out),                               // MSIE from CSR
    .meip_in(csr_meip_out),                               // MEIP from CSR
    .mtip_in(csr_mtip_out),                               // MTIP from CSR
    .msip_in(csr_msip_out)                                // MSIP from CSR
);


 ///////// CSR_File ///////////// 
 wire [11:0] rgb2_csr_addr_out ;
 wire [31:0] rgb2_rs1_reg_out,rgb2_pc_reg_out,rgb2_imm_reg_out,rgb2_iadder_out_reg_out;
 wire [2:0] rgb2_csr_op_out;   
 wire [31:0] csr_data_out;
 wire csr_mie_out;
msrv32_csr_file mcf1 (
    .clk_in(ms_riscv32_mp_clk_in),                         // Clock input
    .rst_in(ms_riscv32_mp_rst_in),                         // Reset input
    .wr_en_in(wr_en_gen_csr_file_wr_en_out),               // Write enable signal for CSR
    .csr_addr_in(rgb2_csr_addr_out),                       // CSR address input
    .csr_op_in(rgb2_csr_op_out),                           // CSR operation (read, write, set, clear)
    .csr_uimm_in(rgb2_imm_reg_out),                        // Immediate value used in CSR instructions
    .csr_data_in(rgb2_rs1_reg_out),                        // Data to write into CSR
    .pc_in(rgb2_pc_reg_out),                               // Current program counter value
    .iadder_in(rgb2_iadder_out_reg_out),                   // Address from instruction adder
    .e_irq_in(ms_riscv32_mp_eirq_in),                      // External interrupt request
    .s_irq_in(ms_riscv32_mp_sirq_in),                      // Software interrupt request
    .t_irq_in(ms_riscv32_mp_tirq_in),                      // Timer interrupt request
    .i_or_e_in(mc_i_or_e_out),                             // 1 → interrupt, 0 → exception
    .set_cause_in(mc_set_cause_out),                       // Signal to set cause register
    .set_epc_in(mc_set_epc_out),                           // Signal to set EPC register
    .instret_inc_in(mc_instret_inc_out),                   // Increment instruction-retired counter
    .mie_clear_in(mc_mie_clear_out),                       // Clear the MIE (machine interrupt enable) bit
    .mie_set_in(mc_mie_set_out),                           // Set the MPIE bit in mstatus
    .cause_in(mc_cause_out),                               // Cause code (4-bit)
    .real_time_in(ms_riscv32_mp_rc_in),                    // Real-time counter input (64-bit)
    .misaligned_exception_in(mc_misaligned_exception_out), // Indicates misaligned memory access exception
    .csr_data_out(csr_data_out),                           // Data read from the CSR
    .mie_out(csr_mie_out),                                 // Current value of MIE bit
    .epc_out(csr_epc_out),                                 // Exception program counter output
    .trap_address_out(csr_trap_address_out),               // Address to jump to on trap
    .meie_out(csr_meie_out),                               // Machine external interrupt enable bit
    .mtie_out(csr_mtie_out),                               // Machine timer interrupt enable bit
    .msie_out(csr_msie_out),                               // Machine software interrupt enable bit
    .meip_out(csr_meip_out),                               // Machine external interrupt pending bit
    .mtip_out(csr_mtip_out),                               // Machine timer interrupt pending bit
    .msip_out(csr_msip_out)                                // Machine software interrupt pending bit
);     


                 
///// reg_block_2 /////////
wire [3:0] alu_opcode_reg_out;
wire [1:0] rgb2_load_size_reg_out;
wire [31:0] rgb2_pc_plus_4_reg_out,rgb2_rs2_reg_out;
wire rgb2_load_unsigned_reg_out,rgb2_alu_src_reg_out;
wire [2:0] rgb2_wb_mux_sel_reg_out;
     msrv32_reg_block2 rgb2 (
    .ms_riscv32_mp_clk_in(ms_riscv32_mp_clk_in),           // Clock signal
    .ms_riscv32_mp_rst_in(ms_riscv32_mp_rst_in),           // Active-high reset signal

    // Decode/Execute stage inputs
    .rd_addr_in(instr_mux_rdaddr_out),                     // Destination register address
    .csr_addr_in(instr_mux_csr_addr_out),                  // CSR address
    .rs1_in(interger_file_rs1_out),                        // Operand 1 (rs1)
    .rs2_in(interger_file_rs2_out),                        // Operand 2 (rs2)
    .pc_in(rgb1_pc_out),                                   // Current PC
    .pc_plus_4_in(pc_pc_plus_4_out),                    // PC + 4
    .branch_taken_in(branch_taken_out),                    // Branch taken indicator
    .iadder_in(iadder_imm_out),                            // Address from instruction address adder
    .alu_opcode_in(decoder_alu_opcode_out),                // ALU operation type
    .load_size_in(decoder_load_size_out),                  // Load size
    .load_unsigned_in(decoder_load_unsigned_out),          // Load unsigned
    .alu_src_in(decoder_alu_src_out),                      // ALU source select
    .csr_wr_en_in(decoder_csr_wr_en_out),                  // CSR write enable
    .rf_wr_en_in(decoder_rf_wr_en_out),                    // Register file write enable
    .wb_mux_sel_in(decoder_wb_mux_sel_out),                // WB mux select
    .csr_op_in(decoder_csr_op_out),                        // CSR operation type
    .imm_in(imm_gen_out),                                  // Immediate value

    // Registered outputs for next pipeline stage
    .rd_addr_reg_out(rgb2_rd_addr_reg_out),                // Registered RD address
    .csr_addr_reg_out(rgb2_csr_addr_out),                  // Registered CSR address
    .rs1_reg_out(rgb2_rs1_reg_out),                        // Registered rs1 value
    .rs2_reg_out(rgb2_rs2_reg_out),                        // Registered rs2 value
    .pc_reg_out(rgb2_pc_reg_out),                          // Registered PC
    .pc_plus_4_reg_out(rgb2_pc_plus_4_reg_out),            // Registered PC + 4
    .iadder_out_reg_out(rgb2_iadder_out_reg_out),          // Registered instruction address
    .alu_opcode_reg_out(alu_opcode_reg_out),               // Registered ALU opcode
    .load_size_reg_out(rgb2_load_size_reg_out),            // Registered load size
    .load_unsigned_reg_out(rgb2_load_unsigned_reg_out),    // Registered load unsigned flag
    .alu_src_reg_out(rgb2_alu_src_reg_out),                // Registered ALU src selector
    .csr_wr_en_reg_out(rgb2_csr_wr_en_reg_out),            // Registered CSR write enable
    .rf_wr_en_reg_out(rgb2_rf_wr_en_reg_out),              // Registered reg file write enable
    .wb_mux_sel_reg_out(rgb2_wb_mux_sel_reg_out),          // Registered WB mux selector
    .csr_op_reg_out(rgb2_csr_op_out),                      // Registered CSR operation type
    .imm_reg_out(rgb2_imm_reg_out)                         // Registered immediate value
);     

         
////// Store_unit /////////////////////////////////////////////////////
wire [1:0] su_funt3_in;
assign su_funt3_in = instr_mux_funct3_out[1:0];
store_unit store_unit_inst (
    .funct3_in(su_funt3_in),                     // Store instruction type (SB, SH, SW) from instruction field
    .iaddr_in(iadder_imm_out),                   // Memory address to write to (alignment checked)
    .rs2_in(interger_file_rs2_out),              // Data to be stored, from Reg_Block2 (rs2 value)
    .mem_wr_req_in(decoder_mem_req_out),         // Memory write request from decoder
    .ahb_ready_in(ms_riscv32_mp_instr_hready_in),// Indicates memory is ready for writing

    .ms_ricv32_dmdata_out(ms_riscv32_mp_dmdata_out),       // Data to be written into memory
    .ms_ricv32_mp_dmaddr_out(ms_riscv32_mp_dmaddr_out),    // Aligned memory address to write to
    .ms_ricv32_mp_dmwr_mask_out(ms_riscv32_mp_dmwr_mask_out), // Byte/halfword/word mask for store
    .ms_ricv32_mp_dmwr_req_out(ms_riscv32_mp_dmwr_req_out),   // Memory write enable signal
    .ahb_htrms_out(ms_riscv32_mp_data_htrans_out)           // Transfer status (valid/invalid transfer indication)
);


//////////////////////////////////////// STAGE-3 /////////////////////////////////////////////////////////////
////////Load_unit//////////////////
 wire [31:0] lu_output_out;
   load_unit lu1 (
    .ahb_rsep_in(ms_riscv32_mp_hresp_in),               // Memory access complete signal (active low)
    .ms_riscv32_mp_dmdata_in(ms_riscv32_mp_dmdata_in),  // 32-bit data from memory
    .iadder_out_1_to_0_in(iadder_decoder_out),          // Last two bits of effective address
    .load_unsigned_in(decoder_load_unsigned_out),       // Indicates if load is unsigned
    .load_size_in(decoder_load_size_out),               // Load size: byte, halfword, word
    .clk(ms_riscv32_mp_clk_in),                         // Clock signal
    .lu_output_out(lu_output_out)                       // Final processed output to integer file
);
//////// ALU////////////////// 
 wire [31:0] wb_sel_mux_2nd_src_out,alu_result_out;
ALU alu_inst (
    .op_1_in(rgb2_rs1_reg_out),           // First operand input (from register block 2)
    .op_2_in(wb_sel_mux_2nd_src_out),     // Second operand input (from WB_MUX)
    .opcode_in(alu_opcode_reg_out),       // ALU operation code (from funct7 & funct3 fields via reg block 2)
    .result_out(alu_result_out)           // ALU operation result (to WB_MUX block)
);
 ////////// WB_Sel_MUX///////////////////////
wb_mux_sel_unit wb_mux_sel_unit_inst (
    .alu_src_reg_in(rgb2_alu_src_reg_out),         // Selects between rs2 and immediate (from reg_block_2)
    .wb_mux_sel_reg_in(rgb2_wb_mux_sel_reg_out),   // 3-bit mux select for WB (from reg_block_2)
    .alu_result_in(alu_result_out),                // ALU result input (from ALU)
    .lu_output_in(lu_output_out),                  // Load Unit output (from Load Unit)
    .imm_reg_in(rgb2_imm_reg_out),                 // Immediate value (from reg_block_2)
    .iadder_out_reg_in(rgb2_iadder_out_reg_out),   // Address adder result (from reg_block_2)
    .csr_data_in(csr_data_out),                    // CSR data output (from CSR file)
    .pc_plus_4_reg_in(rgb2_pc_plus_4_reg_out),     // PC + 4 value (from reg_block_2)
    .rs2_reg_in(rgb2_rs2_reg_out),                 // rs2 register data (from reg_block_2)
    .wb_mux_out(wb_mux_sel_rd_in),                 // Final write-back data to integer file
    .alu_2nd_src_mux_out(wb_sel_mux_2nd_src_out)   // Second operand for ALU (selected based on alu_src)
);      
//////////// fwrite //////////////////////////////////////////////////
fwrite_file1 fwrite_file_inst (
    .clk(ms_riscv32_mp_clk_in),                   // Clock signal
    .reset(ms_riscv32_mp_rst_in),                 // Active-high reset signal
    .rd_en(decoder_rf_wr_en_out),                 // Register file write enable (from decoder)
    .rd_add(instr_mux_rdaddr_out),                // Destination register address
    .pc(rgb2_pc_reg_out),                             // Current instruction PC (from pc_mux)
    .is_load(decoder_is_load),                    // High if current instruction is a load (from decoder)
    .is_store(decoder_is_store),                  // High if current instruction is a store (from decoder)
    .load_unsignned_in(rgb2_load_unsigned_reg_out), // Unsigned load type signal (from load unit)
    .load_size_in(rgb2_load_size_reg_out),        // Load size (byte, half-word, word) (from load unit)
    .mem_radd(iadder_imm_out),                    // Memory read address (from iadder_out_reg_out1)
    .funct3_in(instr_mux_funct3_out),             // Function type for store (from store unit)
    .mem_wadd(iadder_imm_out),                    // Memory write address
    .mem_wdata(ms_riscv32_mp_dmdata_out),         // Memory write data
    .wrd_en1(wr_en_block_integer_file_out),       // Additional write enable (verification)
    .wrd_add1(rgb2_rd_addr_reg_out),              // Additional register address (verification)
    .wrd_data1(wb_mux_sel_rd_in)                  // Additional register data (verification)
);                                      
endmodule

