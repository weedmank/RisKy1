// ----------------------------------------------------------------------------------------------------
// Copyright (c) 2020 Kirk Weedman www.hdlexpress.com
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
// ----------------------------------------------------------------------------------------------------
// Project       :  RisKy1 - new 5 stage pipelined RISC-V ISA based CPU tailored to the RISC-V RV32IM
// Editor        :  Notepad++
// File          :  sfp_instr_cases.svh
// Description   :  This logic is an include file for execute.sv so that execute.sv is more readable
//               :
// Designer      :  Kirk Weedman - kirk@hdlexpress.com
// ----------------------------------------------------------------------------------------------------

   // NOTE: this code is inserted (included) within the wv.sv code
   SPFP_INSTR:
   begin
      case(data_in.op)
         F_LW:
         begin
            if (mis)                                                    // Raise exception for access to an unused address space
            begin
               rld_pc_flag          = TRUE;
               rld_pc_addr          = trap_pc;                          // Trap Vector Base Address
   
               exception.pc         = ipd.pc;                           // address of current instruction to be saved in mepc, sepc, or uepc register
               exception.tval       = ls_addr;                          // acccess fault address
               exception.cause      = 4;                                // 4 = Load Address Misaligned
               exception.flag       = TRUE;

               current_events.misaligned = TRUE;
            end
            else if (MIO_bus.ack_fault)                                 // Raise exception for access fault
            begin
               rld_pc_flag          = TRUE;
               rld_pc_addr          = trap_pc;                          // Trap Vector Base Address
   
               exception.pc         = ipd.pc;                           // address of current instruction to be saved in mepc, sepc, or uepc register
               exception.tval       = ls_addr;                          // bad address
               exception.cause      = 5;                                // 5 = Load Access Fault
               exception.flag       = TRUE;

               current_events.illegal = TRUE;
            end
            else
            begin
               mem_dout.Fd_wr          = Fd_wr;                         // Writeback stage needs to know whether to write to destination register Fd
               mem_dout.Rd_addr        = Rd_addr;                       // Address of Rd register
               mem_dout.Rd_data        = MIO_bus.ack_data;              // value used to update Rd in WB stage
            end
            current_events.fld_retired = TRUE;
         end
   
         F_SW:
         begin
            // Store exceptions can only be done once Store finishes in MEM stage
            if (mis)                                                    // Raise exception for access to an unused address space? p7 Volume I: RISC-V Unprivileged ISA V20190608-Base-Ratified
            begin
               rld_pc_flag          = TRUE;
               rld_pc_addr          = trap_pc;                          // Trap Vector Base Address
   
               exception.pc         = ipd.pc;                           // address of current instruction to be saved in mepc, sepc, or uepc register
               exception.tval       = ls_addr;                          // acccess fault address
               exception.cause      = 6;                                // 6 = Store Address Misaligned
               exception.flag       = TRUE;

               current_events.misaligned = TRUE;
            end
            else if (MIO_bus.ack_fault)                                 // Raise exception for access fault
            begin
               rld_pc_flag          = TRUE;
               rld_pc_addr          = trap_pc;                          // Trap Vector Base Address
   
               exception.pc         = ipd.pc;                           // address of current instruction to be saved in mepc, sepc, or uepc register
               exception.tval       = ls_addr;                          // bad address
               exception.cause      = 7;                                // 7 = Store Access Fault
               exception.flag       = TRUE;

               current_events.illegal = TRUE;
            end
            else
            begin
            end
            current_events.fst_retired = TRUE;
         end
         else
         begin
            if (inv_flag)                                               // A STORE to L1 D$ also wrote to L1 I$ address space
            begin                                                       // This is NOT an exception, but just need to flush pipe and reload I$ due to Load/Store in I$ space
               rld_pc_flag             = TRUE;  
               rld_ic_flag             = TRUE;  
               rld_pc_addr             = ipd.pc + (ci ? 2'd2 : 3'd4);   // reload PC address after this STORE instruction
            end
            // Store does not write any info to GPR registers
            current_events.st_retired  = TRUE;
         end
         
      endcase
   end
