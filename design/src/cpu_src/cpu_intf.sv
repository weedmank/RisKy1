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

// ------------------------ gpr interface ------------------------
interface GPR_RD_intf;
   logic  [GPR_ASZ-1:0] Rs1_addr;
   logic  [GPR_ASZ-1:0] Rs2_addr;

   logic      [RSZ-1:0] Rs1_data;         // data from gpr[RS1_addr]
   logic      [RSZ-1:0] Rs2_data;         // data from gpr[RS2_addr]

   modport master (output Rs1_addr, Rs2_addr, input  Rs1_data, Rs2_data);
   modport slave  (input  Rs1_addr, Rs2_addr, output Rs1_data, Rs2_data);
endinterface: GPR_RD_intf

interface GPR_WR_intf;
   logic                   Rd_wr;         // 1 = write to destination register
   logic     [GPR_ASZ-1:0] Rd_addr;       // Destination Register to write
   logic         [RSZ-1:0] Rd_data;       // data that will be written to the destination register

   modport master (output Rd_wr, Rd_addr, Rd_data);
   modport slave  (input  Rd_wr, Rd_addr, Rd_data);
endinterface: GPR_WR_intf

// ------------------------ fpr interface ------------------------
interface FPR_RD_intf;
   logic    [FPR_ASZ-1:0] FS1_addr;
   logic    [FPR_ASZ-1:0] FS2_addr;

   logic        [RSZ-1:0] Fs1_data;   // data from fpr[FS1_addr]
   logic        [RSZ-1:0] Fs2_data;   // data from fpr[FS2_addr]

   modport master (output FS1_addr, FS2_addr, input  Fs1_data, Fs2_data);
   modport slave  (input  FS1_addr, FS2_addr, output Fs1_data, Fs2_data);
endinterface: FPR_RD_intf

interface FPR_WR_intf;
   logic                   Fd_wr;         // 1 = write to destination register
   logic     [GPR_ASZ-1:0] Fd_addr;       // Destination Register to write
   logic         [RSZ-1:0] Fd_data;       // data that will be written to the destination register

   modport master (output Fd_wr, Fd_addr, Fd_data);
   modport slave  (input  Fd_wr, Fd_addr, Fd_data);
endinterface: FPR_WR_intf

// ------------------------ F2D interface ------------------------
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
   `ifdef ext_N
   logic       [PC_SZ-1:0] uepc;
   `endif
   `endif

   logic       [PC_SZ-1:0] no_br_pc;   // address of instruction immediately following this branch instruction
   logic       [PC_SZ-1:0] br_pc;      // next PC
   `ifndef ext_C
   logic                   mis;        // misaligned address flag
   `endif

   modport master (output Rs1_data, Rs2_data, pc, imm, funct3, ci, sel_x, sel_y, op, mepc, `ifdef ext_S sepc, `endif `ifdef ext_U `ifdef ext_N uepc, `endif `endif input  no_br_pc, `ifndef ext_C mis, `endif br_pc);
   modport slave  (input  Rs1_data, Rs2_data, pc, imm, funct3, ci, sel_x, sel_y, op, mepc, `ifdef ext_S sepc, `endif `ifdef ext_U `ifdef ext_N uepc, `endif `endif output no_br_pc, `ifndef ext_C mis, `endif br_pc);
endinterface: BFU_intf

interface EPC_bus_intf;
   logic       [PC_SZ-1:0] mepc;

   `ifdef ext_S
   logic       [PC_SZ-1:0] sepc;
   `endif

   `ifdef ext_U
   `ifdef ext_N
   logic       [PC_SZ-1:0] uepc;
   `endif
   `endif

   modport master (output `ifdef ext_S sepc, `endif `ifdef ext_U `ifdef ext_N uepc, `endif `endif mepc);
   modport slave  (input  `ifdef ext_S sepc, `endif `ifdef ext_U `ifdef ext_N uepc, `endif `endif mepc);
endinterface: EPC_bus_intf

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

// ------------------------ decode_core.sv interface used in decode.sv ------------------------
interface DCORE_intf;
   FET_2_DEC      fet_data;

   DEC_2_EXE      dec_data;

   modport master (output fet_data, input  dec_data);
   modport slave  (input  fet_data, output dec_data);
endinterface: DCORE_intf

// ------------------------ decode_core.sv interface used in decode.sv ------------------------
interface TRAP_intf;
   logic     [PC_SZ-2-1:0] trap_pc; // lower two bits (always 0) removed in mode_irq() module
   logic                   irq_flag;
   logic         [RSZ-1:0] irq_cause;

   modport master (output trap_pc, irq_flag, irq_cause);
   modport slave  (input  trap_pc, irq_flag, irq_cause);
endinterface: TRAP_intf

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

//------------------------ information shared between CSR Functional Unit and WB stage ------------------------
interface WB2CSR_intf;
   logic             csr_wr;
   logic      [11:0] csr_wr_addr;
   logic   [RSZ-1:0] csr_wr_data;
   logic             sw_irq;           // msip_reg[3] = Software Interrupt Pending - from EXE stage. see csr_fu.sv
   EXCEPTION         exception;
   EVENTS            current_events;   // number of retired instructions for current clock cycle
   logic             mret;
   `ifdef ext_S
   logic             sret;
   `endif
   `ifdef ext_U
   `ifdef ext_N
   logic             uret;
   `endif
   `endif
   logic       [1:0] mode;

   modport master (output csr_wr, csr_wr_addr, csr_wr_data, sw_irq, exception, current_events, `ifdef ext_U `ifdef ext_N uret, `endif `endif `ifdef ext_S sret, `endif mret);
   modport slave  (input  csr_wr, csr_wr_addr, csr_wr_data, sw_irq, exception, current_events, `ifdef ext_U `ifdef ext_N uret, `endif `endif `ifdef ext_S sret, `endif mret);
endinterface: WB2CSR_intf

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

// ------------------------ CSR interfaces ------------------------
interface CSR_NXT_REG_intf;
   `ifdef add_DM
   logic                   Dbg_mode;
   `endif

   `ifdef ext_U
   `ifdef ext_N
   UCSR                    nxt_Ucsr;
   `endif
   `endif

   `ifdef ext_S
   SCSR                    next_Scsr;
   `endif

   MCSR                    nxt_Mcsr;

   modport master (output `ifdef add_DM Dbg_mode `endif `ifdef ext_U `ifdef ext_N nxt_Ucsr, `endif `endif `ifdef ext_S next_Scsr, `endif nxt_Mcsr);
   modport slave  (input  `ifdef add_DM Dbg_mode `endif `ifdef ext_U `ifdef ext_N nxt_Ucsr, `endif `endif `ifdef ext_S next_Scsr, `endif nxt_Mcsr);
endinterface: CSR_NXT_REG_intf

interface CSR_REG_intf;
   `ifdef ext_U
   `ifdef ext_N
   UCSR                    Ucsr;
   `endif
   `endif

   `ifdef ext_S
   SCSR                    Scsr;
   `endif

   MCSR                    Mcsr;

   modport master (output `ifdef ext_U `ifdef ext_N Ucsr, `endif `endif `ifdef ext_S Scsr, `endif Mcsr);
   modport slave  (input  `ifdef ext_U `ifdef ext_N Ucsr, `endif `endif `ifdef ext_S Scsr, `endif Mcsr);
endinterface: CSR_REG_intf


interface CSR_RD_intf;
   logic            [11:0] csr_rd_addr;      // R/W address
   logic                   csr_rd_avail;
   logic         [RSZ-1:0] csr_rd_data;
   logic         [RSZ-1:0] csr_fwd_data;

   modport master (output csr_rd_addr, input  csr_rd_avail, csr_rd_data, csr_fwd_data);
   modport slave  (input  csr_rd_addr, output csr_rd_avail, csr_rd_data, csr_fwd_data);
endinterface: CSR_RD_intf

interface CSR_WR_intf;
   logic                   csr_wr;
   logic            [11:0] csr_wr_addr;
   logic         [RSZ-1:0] csr_wr_data;
   logic                   sw_irq;
   EXCEPTION               exception;
   logic                   current_events;
   logic             [1:0] instr_mode;
   `ifdef ext_U
   `ifdef ext_N
   logic                   uret;
   `endif
   `endif
   `ifdef ext_S
   logic                   sret;
   `endif
   logic                   mret;

   modport master (output csr_wr, csr_wr_addr, csr_wr_data, sw_irq, exception, current_events, instr_mode, `ifdef ext_U `ifdef ext_N uret, `endif `endif `ifdef ext_S sret,`endif mret);
   modport slave  (input  csr_wr, csr_wr_addr, csr_wr_data, sw_irq, exception, current_events, instr_mode, `ifdef ext_U `ifdef ext_N uret, `endif `endif `ifdef ext_S sret,`endif mret);
endinterface: CSR_WR_intf

// ------------------------ CSR Functional Unit interface ------------------------
interface CSRFU_intf;
   // signals from exe.sv to csrfu.sv
   logic                   is_csr_inst;                           // 1 = A CSR instruction is occuring during this clock cylce
   logic            [11:0] csr_addr;                              // R/W address
   logic     [GPR_ASZ-1:0] Rd_addr;                               // Rd address
   logic     [GPR_ASZ-1:0] Rs1_addr;                              // Rs1 address
   logic         [RSZ-1:0] Rs1_data;                              // Contents of R[rs1]
   logic             [2:0] funct3;
   logic             [1:0] mode;                                  // CPU mode: Machine, Supervisor, or User
   logic                   sw_irq;                                // Software Interrupt Pending
   logic         [RSZ-1:0] csr_rd_data;                           // CSR[csr_addr]
   logic                   csr_rd_avail;                          // CSR[csr_addr] is available for use

   // signals from csrfu.sv to exe.sv
   logic                   csr_rd;                                // 1 = read csr_rd_data from CSR[csr_addr]
   logic                   csr_wr;                                // 1 = write csr_wr_data to CSR[csr_addr]
   logic         [RSZ-1:0] csr_rw_data;                           // CSR[csr_addr] plus any software interrupt modifications (depends on csr_addr)
   logic         [RSZ-1:0] csr_wr_data;                           // write data to CSR[csr_addr]
   logic                   ill_csr_access;                        // 1 = illegal csr access
   logic            [11:0] ill_csr_addr;                          // illegal csr address

   modport master (output is_csr_inst, csr_addr, Rd_addr, Rs1_addr, Rs1_data, funct3, mode, sw_irq, csr_rd_data, csr_rd_avail, input  csr_rd, csr_wr, csr_rw_data, csr_wr_data, ill_csr_access, ill_csr_addr);
   modport slave  ( input is_csr_inst, csr_addr, Rd_addr, Rs1_addr, Rs1_data, funct3, mode, sw_irq, csr_rd_data, csr_rd_avail, output csr_rd, csr_wr, csr_rw_data, csr_wr_data, ill_csr_access, ill_csr_addr);
endinterface: CSRFU_intf
