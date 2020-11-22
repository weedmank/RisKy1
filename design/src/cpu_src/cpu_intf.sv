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
// File          :  cpu_intf.sv
// Description   :  interfaces between CPU pipelined stages
//               :
// Designer      :  Kirk Weedman - kirk@hdlexpress.com
// ----------------------------------------------------------------------------------------------------

// ------------------------ CPU pipeline stage interfaces used in RisKy1_core.sv ------------------------

import cpu_params_pkg::*;
import cpu_structs_pkg::*;

interface F2D_intf;
      FET_2_DEC               data;

      logic                   valid;
      logic                   rdy;

      modport master (output data, valid, input  rdy);
      modport slave  (input  data, valid, output rdy);
endinterface: F2D_intf

interface D2E_intf;
      DEC_2_EXE               data;

      logic                   valid;
      logic                   rdy;

      modport master (output data, valid, input  rdy);
      modport slave  (input  data, valid, output rdy);
endinterface: D2E_intf


interface E2M_intf;
      EXE_2_MEM               data;

      logic                   valid;
      logic                   rdy;

      modport master (output data, valid, input  rdy);
      modport slave  (input  data, valid, output rdy);
endinterface: E2M_intf

interface M2W_intf;
      MEM_2_WB                data;

      logic                   valid;
      logic                   rdy;

      modport master (output data, valid, input  rdy);
      modport slave  (input  data, valid, output rdy);
endinterface: M2W_intf

// ------------------------ Functional Unit interfaces used in execute.sv ------------------------

interface AFU_intf;
      logic         [RSZ-1:0] Rs1_data;
      logic         [RSZ-1:0] Rs2_data;
      logic       [PC_SZ-1:0] pc;
      logic         [RSZ-1:0] imm;
      ALU_SEL_TYPE            sel_x;
      ALU_SEL_TYPE            sel_y;
      ALU_OP_TYPE             op;

      logic         [RSZ-1:0] Rd_data;

      modport master (output Rs1_data, Rs2_data, pc, imm, sel_x, sel_y, op, input  Rd_data);
      modport slave  (input  Rs1_data, Rs2_data, pc, imm, sel_x, sel_y, op, output Rd_data);
endinterface: AFU_intf


interface BFU_intf;
      logic         [RSZ-1:0] Rs1_data;
      logic         [RSZ-1:0] Rs2_data;
      logic       [PC_SZ-1:0] pc;
      logic         [RSZ-1:0] imm;
      logic             [2:0] funct3;
      logic                   ci;
      BR_SEL_TYPE             sel_x;
      BR_SEL_TYPE             sel_y;
      BR_OP_TYPE              op;
      logic       [PC_SZ-1:0] mepc;
      `ifdef ext_S
      logic       [PC_SZ-1:0] sepc;
      `endif
      `ifdef ext_U
      logic       [PC_SZ-1:0] uepc;
      `endif

      logic       [PC_SZ-1:0] no_br_pc;   // address of instruction immediately following this branch instruction
      logic       [PC_SZ-1:0] br_pc;      // next PC
      logic                   mis;        // misaligned address flag

      modport master (output Rs1_data, Rs2_data, pc, imm, funct3, ci, sel_x, sel_y, op, mepc, `ifdef ext_S sepc, `endif `ifdef ext_U uepc, `endif input  no_br_pc, br_pc, mis);
      modport slave  (input  Rs1_data, Rs2_data, pc, imm, funct3, ci, sel_x, sel_y, op, mepc, `ifdef ext_S sepc, `endif `ifdef ext_U uepc, `endif output no_br_pc, br_pc, mis);
endinterface: BFU_intf

`ifdef ext_M
interface IMFU_intf;
      logic         [RSZ-1:0] Rs1_data;
      logic         [RSZ-1:0] Rs2_data;
      IM_OP_TYPE              op;

      logic         [RSZ-1:0] Rd_data;

      modport master (output Rs1_data, Rs2_data, op, input  Rd_data);
      modport slave  (input  Rs1_data, Rs2_data, op, output Rd_data);
endinterface: IMFU_intf


interface IDRFU_intf;
      logic         [RSZ-1:0] Rs1_data;
      logic         [RSZ-1:0] Rs2_data;
      IDR_OP_TYPE             op;
      logic                   start;

      logic         [RSZ-1:0] quotient;
      logic         [RSZ-1:0] remainder;
      logic                   done;

      modport master (output Rs1_data, Rs2_data, op, start, input  quotient, remainder, done);
      modport slave  (input  Rs1_data, Rs2_data, op, start, output quotient, remainder, done);
endinterface: IDRFU_intf
`endif


interface LSFU_intf;
      logic         [RSZ-1:0] Rs1_data;
      logic         [RSZ-1:0] Rs2_data;
      logic         [RSZ-1:0] imm;
      logic             [2:0] funct3;

      logic       [PC_SZ-1:0] ls_addr;
      logic         [RSZ-1:0] st_data;
      logic             [2:0] size;
      logic                   zero_ext;
      logic                   mis;

      modport master (output Rs1_data, Rs2_data, imm, funct3, input  ls_addr, st_data, size, zero_ext, mis);
      modport slave  (input  Rs1_data, Rs2_data, imm, funct3, output ls_addr, st_data, size, zero_ext, mis);
endinterface: LSFU_intf


   `ifdef ext_F
   // see spfp_fu.sv
interface SPFPFU_intf;
      logic         [RSZ-1:0] Fs1_data;
      logic         [RSZ-1:0] Fs2_data;
      logic         [RSZ-1:0] imm;
      SPFP_SEL_TYPE           sel_x;
      SPFP_SEL_TYPE           sel_y;
      SPFP_OP_TYPE            op;
      logic                   start;

      logic       [PC_SZ-1:0] ls_addr;
      logic         [RSZ-1:0] st_data;
      logic        [FLEN-1:0] Fd_data;
      logic                   mis;
      logic                   done;

      modport master (output Fs1_data, Fs2_data, imm, sel_x, sel_y, op, start input  ls_addr, st_data, Fd_data, mis, done);
      modport slave  (input  Fs1_data, Fs2_data, imm, sel_x, sel_y, op, start output ls_addr, st_data, Fd_data, mis, done);
endinterface: SPFPFU_intf
   `endif

interface CSRFU_intf;
      logic            [11:0] csr_addr;         // R/W address
      logic                   csr_valid;        // 1 = Read & Write from/to csr[csr_addr] will occur this clock cylce
      logic     [GPR_ASZ-1:0] Rd_addr;
      logic     [GPR_ASZ-1:0] Rs1_addr;
      logic         [RSZ-1:0] Rs1_data;
      logic             [2:0] funct3;

      EXCEPTION               exception;
      EVENTS                  current_events;   // number of retired instructions for current clock cycle
      logic                   mret;             // MRET retiring
      `ifdef ext_S
      logic                   sret;             // SRET retiring
      `endif
      `ifdef ext_U
      logic                   uret;             // URET retiring
      `endif

      logic       [2*RSZ-1:0] mtime;            // memory mapped mtime register
      `ifdef ext_N
      logic                   ext_irq;          // External Interrupt
      logic                   time_irq;         // Timer Interrupt from clint.sv
      logic                   sw_irq;           // Software Interrupt from clint.sv
      `endif

      logic       [PC_SZ-1:0] trap_pc;          // trap vector handler address.
      logic             [1:0] mode;             // Current CPU mode: Machine, Supervisor, or User

      logic         [RSZ-1:0] Rd_data;          // value used to update Rd in WB stage
      `ifdef ext_N
      logic                   interrupt_flag;   // 1 = take an interrupt trap
      logic         [RSZ-1:0] interrupt_cause;  // value specifying what type of interrupt
      `endif
      logic       [PC_SZ-1:0] mepc;             // Machine   : Exception RET PC address
      `ifdef ext_S
      logic       [PC_SZ-1:0] sepc;             // Supervisor: Exception RET PC address
      `endif
      `ifdef ext_U
      logic       [PC_SZ-1:0] uepc;             // User      : Exception RET PC address
      `endif
      logic                   ill_csr_access;   // 1 = illegal csr access
      logic            [11:0] ill_csr_addr;
      logic                   ialign;           // 1 = 16 bit alignment, 0 = 32 bit alignment

      modport master (output csr_addr, csr_valid, Rd_addr, Rs1_addr, Rs1_data, funct3, current_events, mret, `ifdef ext_S sret, `endif `ifdef ext_U uret, `endif
                             mtime, `ifdef ext_N ext_irq, time_irq, sw_irq, `endif exception,
                      input  trap_pc, mode, ialign, Rd_data, `ifdef ext_N interrupt_flag, interrupt_cause, `endif mepc, `ifdef ext_S sepc, `endif `ifdef ext_U uepc, `endif
                             ill_csr_access, ill_csr_addr);
      modport slave  (input  csr_addr, csr_valid, Rd_addr, Rs1_addr, Rs1_data, funct3, current_events, mret, `ifdef ext_S sret, `endif `ifdef ext_U uret, `endif
                             mtime, `ifdef ext_N ext_irq, time_irq, sw_irq, `endif exception,
                      output trap_pc, mode, ialign, Rd_data, `ifdef ext_N interrupt_flag, interrupt_cause, `endif mepc, `ifdef ext_S sepc, `endif `ifdef ext_U uepc, `endif
                             ill_csr_access, ill_csr_addr);
endinterface: CSRFU_intf


// ------------------------ decode_core.sv interface used in decode.sv ------------------------
interface DCORE_intf;
      FET_2_DEC      fet_data;

      DEC_2_EXE      dec_data;

      modport master (output fet_data, input  dec_data);
      modport slave  (input  fet_data, output dec_data);

endinterface: DCORE_intf
// ------------------------ gpr interface ------------------------
interface RBUS_intf;
      logic                   Rd_wr;         // 1 = write to destination register
      logic     [GPR_ASZ-1:0] Rd_addr;       // Destination Register to write
      logic         [RSZ-1:0] Rd_data;       // data that will be written to the destination register

      modport master (output Rd_wr, Rd_addr, Rd_data);
      modport slave  (input  Rd_wr, Rd_addr, Rd_data);

endinterface: RBUS_intf

// ------------------------ fpr interface ------------------------
interface FBUS_intf;
      logic                   Fd_wr;         // 1 = write to destination register
      logic     [GPR_ASZ-1:0] Fd_addr;       // Destination Register to write
      logic         [RSZ-1:0] Fd_data;       // data that will be written to the destination register

      modport master (output Fd_wr, Fd_addr, Fd_data);
      modport slave  (input  Fd_wr, Fd_addr, Fd_data);

endinterface: FBUS_intf

// ------------------------ L1 Instruction & Data Cache Interfaces ------------------------
interface L1IC_intf;
      logic                   req;           // Fetch unit is requesting a cache line of data from the I $
      logic       [PC_SZ-1:0] addr;          // Memory address that Fetch unit wants to get a cache line of data from
                                                
      logic                   ack;           // I$ is ackknowledging it has data (ic_rd_data_in) for the Fetch unit
      logic    [CL_LEN*8-1:0] ack_data;      // this contains CL_LEN bytes of data => CL_LEN/4 instructions
      logic                   ack_fault;

      modport master (output addr, req, input  ack, ack_data, ack_fault);
      modport slave  (input  addr, req, output ack, ack_data, ack_fault);

endinterface: L1IC_intf


interface L1DC_intf;
      logic                   req;
      L1DC_Req_Data           req_data;

      logic                   ack;
      logic         [RSZ-1:0] ack_data;
      logic                   ack_fault;

      modport master (output req, req_data, input  ack, ack_data, ack_fault);
      modport slave  (input  req, req_data, output ack, ack_data, ack_fault);

endinterface: L1DC_intf

//------------------------ information shared betwee CSR Functional Unit and WB stage ------------------------
interface EV_EXC_intf;
      EXCEPTION               exception;
      EVENTS                  current_events;   // number of retired instructions for current clock cycle

      modport master (output exception, current_events);
      modport slave  (input  exception, current_events);

endinterface: EV_EXC_intf

//------------------------ Loads & Stores that need to be saved into the LS Queue ------------------------
`ifdef add_LSQ
interface MEM2LSQ_intf;
      logic                   valid;
      logic                   rdy;
      MEM_LS_Data             data;

      modport master (output valid, data, input  rdy);
      modport slave  (input  valid, data, output rdy);

endinterface: MEM2LSQ_intf
`endif

// ------------------------ MEM stage External I/O bus ------------------------
interface EIO_intf;
      logic                      req;                                // I/O Request
      logic          [PC_SZ-1:0] addr;                               // I/O Address
      logic                      rd;                                 // I/O Read signal. 1 = read
      logic                      wr;                                 // I/O Write signal. 1 = write
      logic            [RSZ-1:0] wr_data;                            // I/O Write data that is written when io_wr == 1

      logic                      ack;                                // I/O Acknowledge
      logic                      ack_fault;                          // I/O Fault - checked during ack
      logic            [RSZ-1:0] ack_data;                           // I/O Read data

      modport master(output req, addr, rd, wr, wr_data, input  ack_data, ack, ack_fault);
      modport slave (input  req, addr, rd, wr, wr_data, output ack_data, ack, ack_fault);
endinterface: EIO_intf