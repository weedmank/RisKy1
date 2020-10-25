// ----------------------------------------------------------------------------------------------------
// Creative Commons - Attribution - ShareAlike 3.0
// Copyright (c) 2019 Kirk Weedman www.hdlexpress.com
// Notice: For any reuse or distribution, you must make clear to others the license terms of this work.
// see http://creativecommons.org/licenses/by/3.0/
// ----------------------------------------------------------------------------------------------------
// Project       :  RisKy1 - new 5 stage pipelined RISC-V ISA based CPU tailored to the RISC-V RV32IM
// Editor        :  Notepad++
// File          :  spfp_fu.sv
// Description   :  single precision Floating Point operations
//               :
// Designer      :  Kirk Weedman - kirk@hdlexpress.com
// ----------------------------------------------------------------------------------------------------

`timescale 1ns/100ps

`ifdef ext_F

`include "functions.svh"
`include "logic_params.svh"
`include "cpu_params.svh"
`include "cpu_structs.svh"

module spfp_fu
(
   SPFPFU.slave     spfpfu_bus
);

   logic     [FLEN-1:0] mux_x;
   logic     [FLEN-1:0] mux_y;

   // separated input data
   logic     [FLEN-1:0] Fs1_data;
   logic     [FLEN-1:0] Fs2_data;
   logic     [FLEN-1:0] imm;
   SPFP_SEL_TYPE        sel_x;
   SPFP_SEL_TYPE        sel_y;
   SPFP_OP_TYPE         op;
   logic                start;

   logic    [PC_SZ-1:0] pc;

   // pull out the signals
   assign Fs1_data   = spfpfu_bus.Fs1_data;
   assign Fs2_data   = spfpfu_bus.Fs2_data;
   assign imm        = spfpfu_bus.imm;
   assign sel_x      = spfpfu_bus.sel_x;
   assign sel_y      = spfpfu_bus.sel_y;
   assign op         = spfpfu_bus.op;
   assign start      = spfpfu_bus.start;
   
   // full_case — at least one item is true
   // parallel_case — at most one item is true
   always_comb
   begin
      case(sel_x) // synopsys parallel_case
         FM_RS1:  mux_x = Fs1_data;
         FM_RS2:  mux_x = Fs2_data;
         FM_IMM:  mux_x = imm;
      endcase
   end

   always_comb
   begin
      case(sel_y) // synopsys parallel_case
         FM_RS1:  mux_y = Fs1_data;
         FM_RS2:  mux_y = Fs2_data;
         FM_IMM:  mux_y = imm;
      endcase
   end

   // SPFP Operations
   always_comb
   begin
      spfpfu_bus.ls_addr   = 'd0;
      spfpfu_bus.st_data   = 'd0;
      spfpfu_bus.Fd_data   = 'd0;
      spfpfu_bus.mis       = FALSE;
      spfpfu_bus.done      = FALSE;

      case(op) // synopsys parallel_case
         F_LW:
         begin
            spfpfu_bus.ls_addr = mux_x + mux_y;
            spfpfu_bus.mis = spfpfu_bus.ls_addr[1:0] != 2'b00;
            spfpfu_bus.done = start;
         end

         F_SW:
         begin
            spfpfu_bus.ls_addr = mux_x + mux_y;
            spfpfu_bus.st_data = Fs2_data;
            spfpfu_bus.mis = spfpfu_bus.ls_addr[1:0] != 2'b00;
            spfpfu_bus.done = start;
         end

         //!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! CODE NEEDS TO BE FINISHED BELOW HERE !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

         F_MADD:
         begin
            spfpfu_bus.Fd_data = 0;
         end

         F_MSUB:
         begin
            spfpfu_bus.Fd_data = 0;
         end

         F_NMSUB:
         begin
            spfpfu_bus.Fd_data = 0;
         end

         F_NMADD:
         begin
            spfpfu_bus.Fd_data = 0;
         end

         F_ADD:
         begin
            spfpfu_bus.Fd_data = 0;
         end

         F_SUB:
         begin
            spfpfu_bus.Fd_data = 0;
         end

         F_MUL:
         begin
            spfpfu_bus.Fd_data = 0;
         end

         F_DIV:
         begin
            spfpfu_bus.Fd_data = 0;
         end

         F_SQRT:
         begin
            spfpfu_bus.Fd_data = 0;
         end

         F_SGNJ:
         begin
            spfpfu_bus.Fd_data = 0;
         end

         F_SGNJN:
         begin
            spfpfu_bus.Fd_data = 0;
         end

         F_SGNJX:
         begin
            spfpfu_bus.Fd_data = 0;
         end

         F_MIN:
         begin
            spfpfu_bus.Fd_data = 0;
         end

         F_MAX:
         begin
            spfpfu_bus.Fd_data = 0;
         end

         F_CVTW:
         begin
            spfpfu_bus.Fd_data = 0;
         end

         F_CVTWU:
         begin
            spfpfu_bus.Fd_data = 0;
         end

         F_MVXW:
         begin
            spfpfu_bus.Fd_data = 0;
         end

         F_EQ:
         begin
            spfpfu_bus.Fd_data = 0;
         end

         F_LT:
         begin
            spfpfu_bus.Fd_data = 0;
         end

         F_LE:
         begin
            spfpfu_bus.Fd_data = 0;
         end

         F_CLASS:
         begin
            spfpfu_bus.Fd_data = 0;
         end

         F_CVSW:
         begin
            spfpfu_bus.Fd_data = 0;
         end

         F_CVSWU:
         begin
            spfpfu_bus.Fd_data = 0;
         end

         F_MVWX:
         begin
            spfpfu_bus.Fd_data = 0;
         end

      endcase
   end

endmodule

`endif