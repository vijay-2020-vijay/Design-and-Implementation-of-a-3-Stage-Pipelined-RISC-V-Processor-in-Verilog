`timescale 1ns / 1ps
module RISCV_test_top (
    //---------------- Clock and Reset ----------------//
    input        ms_riscv32_mp_clk_in,          // System clock input - drives all synchronous logic
    input        ms_riscv32_mp_rst_in,          // Asynchronous reset input (active high) - resets processor FSMs, registers, etc.

    //---------------- Instruction Fetch Interface ----------------//
    input        ms_riscv32_mp_instr_hready_in, // Instruction memory ready signal (AHB) - indicates that fetched instruction is valid
    input        ms_riscv32_mp_hresp_in,        // AHB response signal (0: OKAY, 1: ERROR) - informs processor of access status

    //---------------- CSR / Timer Interface ----------------//
    input  [63:0] ms_riscv32_mp_rc_in,          // Real-time counter input (e.g., mcycle or external timer value)

    //---------------- Data Memory Interface ----------------//
    input        ms_riscv32_mp_data_hready_in,  // Data memory ready signal (AHB) - indicates completion of data phase

    //---------------- Interrupt Inputs ----------------//
    input        ms_riscv32_mp_eirq_in,         // External interrupt request input - triggers M-mode interrupt
    input        ms_riscv32_mp_tirq_in,         // Timer interrupt request input - used by CLINT or MTIME
    input        ms_riscv32_mp_sirq_in,         // Software interrupt request input - CSR-based software trap

    //---------------- Outputs ----------------//
    output       ms_riscv32_mp_dmwr_req_out,    // Data memory write request output - goes high during STORE operation
    output [31:0] ms_riscv32_mp_imaddr_out,     // Instruction memory address output - typically the Program Counter (PC)
    output [1:0]  ms_riscv32_mp_data_htrans_out // AHB transfer type signal - 2'b10 = NONSEQ, 2'b00 = IDLE, etc.
);

    wire [31:0] ms_riscv32_mp_dmdata_in, ms_riscv32_mp_instr_in;
    wire [31:0] ms_riscv32_mp_dm_addr_out,ms_riscv32_mp_dmdata_out;
    wire  [3:0] ms_riscv32_mp_dmwr_mask_out;
    wire [31:0]pc_mux_out_risc_mainmodule;
////////////////////////////////////////////////////////////////////////////////////////////////////////////////    
RISCV_32I_TOP RISCV_32I_TOP_inst (
    //---------------- Clock and Reset ----------------//
    .ms_riscv32_mp_clk_in(ms_riscv32_mp_clk_in),               // System clock input
    .ms_riscv32_mp_rst_in(ms_riscv32_mp_rst_in),               // Asynchronous reset input (active high)

    //---------------- Instruction Interface ----------------//
    .ms_riscv32_mp_instr_hready_in(ms_riscv32_mp_instr_hready_in), // Instruction memory ready signal (from AHB)
    .ms_riscv32_mp_instr_in(ms_riscv32_mp_instr_in),               // 32-bit instruction fetched from instruction memory

    //---------------- Data Memory Interface ----------------//
    .ms_riscv32_mp_dmdata_in(ms_riscv32_mp_dmdata_in),         // Data loaded from memory (LOAD instructions)
    .ms_riscv32_mp_dmwr_req_out(ms_riscv32_mp_dmwr_req_out),   // Write request output signal (high during STORE)
    .ms_riscv32_mp_dmaddr_out(ms_riscv32_mp_dm_addr_out),      // Address to access data memory (LOAD/STORE)
    .ms_riscv32_mp_dmdata_out(ms_riscv32_mp_dmdata_out),       // Data to write to memory (STORE instruction)
    .ms_riscv32_mp_dmwr_mask_out(ms_riscv32_mp_dmwr_mask_out), // Byte write mask (1 = write byte i)
    .ms_riscv32_mp_data_htrans_out(ms_riscv32_mp_data_htrans_out), // AHB HTRANS output for data transaction (IDLE/NONSEQ)

    //---------------- AHB Handshake & Response ----------------//
    .ms_riscv32_mp_hresp_in(ms_riscv32_mp_hresp_in),           // AHB response from memory (0: OKAY, 1: ERROR)
    .ms_riscv32_mp_hready_in(ms_riscv32_mp_data_hready_in),    // AHB data ready (memory interface is ready to complete access)

    //---------------- CSR / Performance ----------------//
    .ms_riscv32_mp_rc_in(ms_riscv32_mp_rc_in),                 // Real-time counter input (e.g., mcycle, mtimer)

    //---------------- Interrupt Inputs ----------------//
    .ms_riscv32_mp_eirq_in(ms_riscv32_mp_eirq_in),             // External interrupt (M-mode)
    .ms_riscv32_mp_tirq_in(ms_riscv32_mp_tirq_in),             // Timer interrupt (M-mode)
    .ms_riscv32_mp_sirq_in(ms_riscv32_mp_sirq_in),             // Software interrupt (M-mode)

    //---------------- Instruction Address Output ----------------//
    .ms_riscv32_mp_iadder_out(ms_riscv32_mp_imaddr_out),       // Instruction address (Program Counter) - used to fetch next instruction

    //---------------- Debug/Status Output ----------------//
    .pc_mux_out_risc(pc_mux_out_risc_mainmodule)               // Internal signal (possibly for debug or instruction control unit status)
);

//////////////////////////instraction  memorey instantiations//////////////////////////////////////////////////////////////////////////////////////
I_cache instr_mem (
    .clk(ms_riscv32_mp_clk_in),                // Clock input
    .reset(ms_riscv32_mp_rst_in),              // Reset input
    .addr(pc_mux_out_risc_mainmodule),         // Address from PC mux
    .rdata(ms_riscv32_mp_instr_in)             // Output instruction data
); 
//////////////////////////////// data memory /////////////////////////////////////////////////////////////////////////////////////////////////////    
D_cache data_mem (
    .clk(ms_riscv32_mp_clk_in),                // Clock input
    .reset(ms_riscv32_mp_rst_in),              // Reset input
    .addr(ms_riscv32_mp_dm_addr_out),          // Data memory address
    .rdata(ms_riscv32_mp_dmdata_in),           // Data read from memory
    .wen(ms_riscv32_mp_dmwr_mask_out),         // Write enable/mask signals
    .wdata(ms_riscv32_mp_dmdata_out)           // Data to write into memory
);
endmodule
///////////data memory/////////////////////////////////////////////////////////
 module D_cache #(
         parameter  ADD_WIDTH = 18,
         parameter      DEPTH = (2**ADD_WIDTH)/4
     )(
     input clk,reset,
     
     input  [31:0] addr,
     output [31:0] rdata,
     input  [ 3:0] wen,
     input  [31:0] wdata
 );
     
     reg [31:0] mem [0:DEPTH-1];
 
 //wire [31:0]data_at_address; 
 
 
 initial $readmemh("D:/verilog_11/project_15RISC_V_3Stage_Final/memory.hex",mem);// for sever
 //initial $readmemh("D:/RISC V/memor.hex",mem);// for pc
 //// ----------------------        Read Channel        -------------------- ////
     
     wire [ADD_WIDTH-3:0] mem_add   = addr[ADD_WIDTH-1:2] ;
     wire [31:0]          mem_rdata;
     
     assign  mem_rdata= mem[mem_add] ;
     
     assign rdata = mem_rdata;
     
 // ----------------------        Write Channel        -------------------- ////
     
     wire [31:0] wdata1;
     assign wdata1[31:24] = (wen[3]) ? wdata[31:24] : mem_rdata[31:24];
     assign wdata1[23:16] = (wen[2]) ? wdata[23:16] : mem_rdata[23:16];
     assign wdata1[15: 8] = (wen[1]) ? wdata[15: 8] : mem_rdata[15: 8];
     assign wdata1[ 7: 0] = (wen[0]) ? wdata[ 7: 0] : mem_rdata[ 7: 0];
     
     always@(posedge clk) if( !reset & wen!=3'b000 ) mem[mem_add] <= wdata1;
 
 
 //assign data_at_address = mem[192508];
     
 endmodule
 
 ///////////////////cache memory //////////////////////////////////////////////////////
 
 module I_cache #(
         parameter  ADD_WIDTH = 17,
         parameter      DEPTH = (2**ADD_WIDTH)/4
     )(
     input clk,reset,
     input  [31:0] addr,
     output reg [31:0] rdata
     
 );
     
     reg [31:0] mem [0:DEPTH-1];
     
     
 initial $readmemh("D:/verilog_11/project_15RISC_V_3Stage_Final/memory.hex",mem); // for sever
 //initial $readmemh("D:/RISC V/memor.hex",mem);
     
 //// ----------------------        Read Channel        -------------------- ////
     
     wire [ADD_WIDTH-3:0] mem_add   = addr[ADD_WIDTH-1:2] ;
     wire [31:0]          mem_rdata = mem[mem_add] ;
     
      
     always@(posedge clk) begin
       if   (reset) rdata <= 32'd0;
 //      else if(addr==32'h00000000) rdata <= 32'd0;
       else         rdata <= mem_rdata;
     end
     
 endmodule
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 
    

