`timescale 1ns / 1ps 
//////////////////////////////////////////////////////////////////////////////////
module pc(
input rst_in,///coming from top module//when it is active provide BOOT_address
input[1:0]pc_src_in,//2bit infometion//coming from(machine_control blocK)//it triggers ;boot address,epc_in address,trap_addresss_in,normal address
input[31:0]pc_in,//it will always carry the address of the current instraction//coming from(Reg_block1)
input[31:0]epc_in,//intrrupt_return address //coming from (CSR_file)
input[31:0]trap_address_in,//intrrupt_address where survice should be provided immediately//coming from(CSR_file)
input branch_taken_in,//control signal for branching conformetion//coming from (branching unit)
input[31:1]iadder_in,///when branch kind of instraction is happening ,it will provide the address//immediate kind of address//here_we_will_provide_[31:1]=31bits
input ahb_ready_in,//coming from the memorey instraction block whenever it is ready to pick up the new address or not//coming from(instraction memorey itself)
output reg[31:0]iadder_out,//this is the final instraction_address goes to insreaction memorey to featch the instraction from the memorey 
output[31:0]pc_plus_4_out,/// it will carry pc(current_instraction_address)+4 which will be used for return address_storeing purpose//goes to reg_block1
output reg misaligned_instr_logic_out,//during jumping if jumping address is missmatched.it will imformed immediately
output reg[31:0]pc_max_out///it also carry the all kind of instraction but does not allow to fatch the instraction from the memorey//it is stroed within
//reg_block1 .for cheaking Debug,internal cheak,missallignment cheaking.
);

wire[31:0] Boot_address;
reg[31:0] next_pc;
assign Boot_address=32'h00000200; //0r32'h80000000
assign pc_plus_4_out=pc_in+32'd4;///////single line combinational circuits not need to require always block////

//////////////////////////////////////////////////////////////////////////////////////
always@(*)begin
          case(pc_src_in)
          2'b00:begin
             pc_max_out=Boot_address;
          end
          2'b01:begin
             pc_max_out=epc_in; 
          end
          2'b10:begin 
             pc_max_out=trap_address_in;
          end
          2'b11:begin
             pc_max_out=next_pc;
          end
          default: pc_max_out=next_pc;
          endcase 
end
////////////////////////////////////////////////////////////////////////////////////////////
always@(*) begin
           if( branch_taken_in==1'b1)begin
                next_pc={iadder_in[31:1],1'b0};///becomes32_bit
           end
           else begin
                next_pc=pc_plus_4_out;
           end 
end
////////////////////////////////////////////////////////////////////////////////////////////////
always@(*) begin
          if(next_pc[1]==1 && branch_taken_in)begin
                misaligned_instr_logic_out=1'b1;
          end
          else  begin
                misaligned_instr_logic_out=1'b0;
          end   
end

////////////////////////////////////////////////////////////////////////////////////////////////
always@(*)begin
          if(rst_in)begin
             iadder_out=Boot_address;
          end
          else if(ahb_ready_in)begin
             iadder_out=pc_max_out;
          end
          else begin
             // iaddr_out=iaddr_out; // if we do this the latch will be created .combinetional circuit can not hold the value 
             // so the solution is //if you tuly need to hold the pc value then have to use clk ortherwise it is not possible ///
             iadder_out=iadder_out;
             //32'h00000000;//avoiding this problem . it is shifted to the 00000000 location where no operation has benn performed.
         end 
end
/////////////////////////////////////////////////////////////////////////////////////
endmodule
