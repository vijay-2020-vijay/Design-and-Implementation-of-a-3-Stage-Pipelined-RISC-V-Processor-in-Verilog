`timescale 1ns / 1ps 
//////////////////////////////////////////////////////////////////////////////////
module test_top_tb();
    reg ms_riscv32_mp_clk_in,ms_riscv32_mp_rst_in,ms_riscv32_mp_instr_hready_in;
    reg ms_riscv32_mp_hresp_in;
    reg [63:0]ms_riscv32_mp_rc_in;
    reg ms_riscv32_mp_data_hready_in,ms_riscv32_mp_eirq_in,ms_riscv32_mp_tirq_in,ms_riscv32_mp_sirq_in;
    wire ms_riscv32_mp_dmwr_req_out;
    wire [31:0]ms_riscv32_mp_imaddr_out;    
    wire [1:0] ms_riscv32_mp_data_htrans_out ;
//////////////////////////////////////////////////////////////////////////////////////////////////////    
  RISCV_test_top mp (
    //---------------- Clock and Reset ----------------//
    .ms_riscv32_mp_clk_in(ms_riscv32_mp_clk_in),                 // Clock input to drive the processor core
    .ms_riscv32_mp_rst_in(ms_riscv32_mp_rst_in),                 // Asynchronous reset (active high)
    //---------------- Instruction Memory Interface ----------------//
    .ms_riscv32_mp_instr_hready_in(ms_riscv32_mp_instr_hready_in), // Instruction memory ready signal (AHB HREADYI)
    .ms_riscv32_mp_hresp_in(ms_riscv32_mp_hresp_in),             // AHB response signal from instruction/data memory (0 = OKAY, 1 = ERROR)
    .ms_riscv32_mp_rc_in(ms_riscv32_mp_rc_in),                   // Real-time counter input (64-bit), often tied to `mcycle` or system clock
    //---------------- Data Memory Interface ----------------//
    .ms_riscv32_mp_data_hready_in(ms_riscv32_mp_data_hready_in), // Data memory ready signal (AHB HREADY)
    //---------------- Interrupt Inputs ----------------//
    .ms_riscv32_mp_eirq_in(ms_riscv32_mp_eirq_in),               // External interrupt request input (M-mode interrupt)
    .ms_riscv32_mp_tirq_in(ms_riscv32_mp_tirq_in),               // Timer interrupt request input (M-mode interrupt)
    .ms_riscv32_mp_sirq_in(ms_riscv32_mp_sirq_in),               // Software interrupt request input (M-mode interrupt)
    //---------------- Outputs to Memory ----------------//
    .ms_riscv32_mp_dmwr_req_out(ms_riscv32_mp_dmwr_req_out),     // Write request signal to data memory (for STORE instructions)
    .ms_riscv32_mp_imaddr_out(ms_riscv32_mp_imaddr_out),         // Instruction memory address output (usually the current PC)
    .ms_riscv32_mp_data_htrans_out(ms_riscv32_mp_data_htrans_out) // Transfer type for AHB transaction: 2'b10 = NONSEQ, 2'b00 = IDLE
);

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    always #5 ms_riscv32_mp_clk_in=~ms_riscv32_mp_clk_in;
    initial begin
    //---------------- Clock and Reset ----------------//
    ms_riscv32_mp_clk_in <= 1;// Clock initialized high (will toggle in an always block later)
    ms_riscv32_mp_rst_in <= 1;// Reset is active (1 = asserted)  // At the beginning of simulation, reset should be high to initialize all modules
    //---------------- AHB Control and Handshaking ----------------//                                  
    ms_riscv32_mp_hresp_in <= 0;// AHB response = 0 (OKAY)   // No error response from memory bus; default behavior for successful transaction
    ms_riscv32_mp_data_hready_in <= 1;     // AHB data ready = 1 // This means memory is ready to complete a transaction immediately //No wait state inserted
    ms_riscv32_mp_instr_hready_in <= 1;    // Instruction memory ready = 1 // The instruction bus is not stalled - fetch can proceed without wait                                 
    ms_riscv32_mp_rc_in <= 64'b0;// Real-time counter (e.g., mcycle) initialized to 0   // Used for benchmarking, performance count, or CSR access                                   
   //---------------- Interrupts ----------------//
   ms_riscv32_mp_eirq_in <= 0;            // External interrupt = 0 (inactive)  // No external interrupt is triggered at simulation start                                     
   ms_riscv32_mp_tirq_in <= 0;            // Timer interrupt = 0 (inactive)// No timer event is pending at simulation start                                     
   ms_riscv32_mp_sirq_in <= 0;            // Software interrupt = 0 (inactive)  // CSR-based software interrupt not triggered initially

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////         
    #50
    ms_riscv32_mp_rst_in<=0;
      
    //#100000
    //$stop();
    //$finish();
    end     
endmodule

