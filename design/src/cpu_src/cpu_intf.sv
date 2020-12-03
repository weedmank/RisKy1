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
      logic                   csr_valid;        // 1 = Read & Write from/to csr[csr_addr] will occur this clock cylce
      logic            [11:0] csr_addr;         // R/W address
      logic                   csr_avail;
      logic         [RSZ-1:0] csr_rd_data;      // current CSR[csr_addr]
      logic     [GPR_ASZ-1:0] Rd_addr;
      logic     [GPR_ASZ-1:0] Rs1_addr;
      logic         [RSZ-1:0] Rs1_data;
      logic             [2:0] funct3;
      logic             [1:0] mode;             // Current CPU mode: Machine, Supervisor, or Use

      logic                   csr_wr;
      logic                   csr_rd;
      logic         [RSZ-1:0] Rd_data;          // data for R[Rd]
      logic         [RSZ-1:0] csr_wr_data;      // value used to update CSR[csr_addr} in WB stage
      logic         [RSZ-1:0] nxt_csr_rd_data;  // data to use as forwarding value for CSR[csr_addr]
      logic                   ill_csr_access;   // 1 = illegal csr access
      logic            [11:0] ill_csr_addr;

      modport master (output csr_valid, csr_addr, csr_avail, csr_rd_data, Rd_addr, Rs1_addr, Rs1_data, funct3, mode,
                      input  csr_wr, csr_rd, Rd_data, csr_wr_data, nxt_csr_rd_data, ill_csr_access, ill_csr_addr);
      modport slave  (input  csr_valid, csr_addr, csr_avail, csr_rd_data, Rd_addr, Rs1_addr, Rs1_data, funct3, mode,
                      output csr_wr, csr_rd, Rd_data, csr_wr_data, nxt_csr_rd_data, ill_csr_access, ill_csr_addr);
endinterface: CSRFU_intf


// ------------------------ WB to CSR write interface port ------------------------
interface WB_2_CSR_wr_intf;
   logic             csr_wr;
   logic      [11:0] csr_wr_addr;
   logic   [RSZ-1:0] csr_wr_data;

   modport master (output csr_wr, csr_wr_addr, csr_wr_data);
   modport slave  (input  csr_wr, csr_wr_addr, csr_wr_data);
endinterface: WB_2_CSR_wr_intf

// ------------------------ CSR Read interface port ------------------------
interface RCSR_intf;
   logic      [11:0] csr_rd_addr;
   logic   [RSZ-1:0] csr_rd_data;
   logic             csr_rd_avail;

   modport master (output csr_rd_addr, input  csr_rd_data, csr_rd_avail);
   modport slave  (input  csr_rd_addr, output csr_rd_data, csr_rd_avail);
endinterface: RCSR_intf

// ------------------------ CSR Next interface port ------------------------
interface CSR_NXT_intf;
   logic             nxt_csr_wr;
   logic      [11:0] nxt_csr_wr_addr;
   logic   [RSZ-1:0] nxt_csr_wr_data;
   logic   [RSZ-1:0] nxt_csr_rd_data;

   modport master (output nxt_csr_wr, nxt_csr_wr_addr, nxt_csr_wr_data, input  nxt_csr_rd_data);
   modport slave  (input  nxt_csr_wr, nxt_csr_wr_addr, nxt_csr_wr_data, output nxt_csr_rd_data);
endinterface: CSR_NXT_intf

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


// ------------------------ Interrupt Requests ------------------------
//interface IRQ_intf;
//   logic    ext;
//   logic    timer;
//   logic    sw;
//
//   modport master(output ext, timer, sw);
//   modport slave (input  ext, timer, sw);
//endinterface: IRQ_intf

// ------------------------ Machine mode CSRs ------------------------
//interface MCSR_REG_intf;
//   MCSR     mcsr;
//   
//   modport master(output  `ifdef ext_S medeleg, mideleg,`else `ifdef ext_U `ifdef ext_N medeleg, mideleg, `endif `endif `endif
//                          mstatus, misa, `ifdef ext_N mie, `endif mtvec, mcounteren, mcountinhibit, `ifdef use_MHPM mhpmevent, `endif mscratch,
//                          mepc, mcause, mtval, `ifdef ext_N mip, `endif `ifdef USE_PMPCFG pmpcfg0, pmpcfg1, pmpcfg2, pmpcfg3, `endif
//                          `ifdef PMP_ADDR0  pmpaddr0,  `endif `ifdef PMP_ADDR1  pmpaddr1,  `endif `ifdef PMP_ADDR2  pmpaddr2,  `endif `ifdef PMP_ADDR3  pmpaddr3,  `endif
//                          `ifdef PMP_ADDR4  pmpaddr4,  `endif `ifdef PMP_ADDR5  pmpaddr5,  `endif `ifdef PMP_ADDR6  pmpaddr6,  `endif `ifdef PMP_ADDR7  pmpaddr7,  `endif
//                          `ifdef PMP_ADDR8  pmpaddr8,  `endif `ifdef PMP_ADDR9  pmpaddr9,  `endif `ifdef PMP_ADDR10 pmpaddr10, `endif `ifdef PMP_ADDR11 pmpaddr11, `endif
//                          `ifdef PMP_ADDR12 pmpaddr12, `endif `ifdef PMP_ADDR13 pmpaddr13, `endif `ifdef PMP_ADDR14 pmpaddr14, `endif `ifdef PMP_ADDR15 pmpaddr15, `endif
//                          `ifdef add_DM tselect, tdata1, tdata2, tdata3, dcsr, dpc, dscratch0, dscratch1, `endif mcycle_lo, mcycle_hi,
//                          minstret_lo, minstret_hi, `ifdef use_MHPM mhpmcounter_lo, mhpmcounter_hi, `endif  mvendorid, marchid, mimpid, mhartid
//                          );
//   modport slave (input   `ifdef ext_S medeleg, mideleg,`else `ifdef ext_U `ifdef ext_N medeleg, mideleg, `endif `endif `endif
//                          mstatus, misa, `ifdef ext_N mie, `endif mtvec, mcounteren, mcountinhibit, `ifdef use_MHPM mhpmevent, `endif mscratch,
//                          mepc, mcause, mtval, `ifdef ext_N mip, `endif `ifdef USE_PMPCFG pmpcfg0, pmpcfg1, pmpcfg2, pmpcfg3, `endif
//                          `ifdef PMP_ADDR0  pmpaddr0,  `endif `ifdef PMP_ADDR1  pmpaddr1,  `endif `ifdef PMP_ADDR2  pmpaddr2,  `endif `ifdef PMP_ADDR3  pmpaddr3,  `endif
//                          `ifdef PMP_ADDR4  pmpaddr4,  `endif `ifdef PMP_ADDR5  pmpaddr5,  `endif `ifdef PMP_ADDR6  pmpaddr6,  `endif `ifdef PMP_ADDR7  pmpaddr7,  `endif
//                          `ifdef PMP_ADDR8  pmpaddr8,  `endif `ifdef PMP_ADDR9  pmpaddr9,  `endif `ifdef PMP_ADDR10 pmpaddr10, `endif `ifdef PMP_ADDR11 pmpaddr11, `endif
//                          `ifdef PMP_ADDR12 pmpaddr12, `endif `ifdef PMP_ADDR13 pmpaddr13, `endif `ifdef PMP_ADDR14 pmpaddr14, `endif `ifdef PMP_ADDR15 pmpaddr15, `endif
//                          `ifdef add_DM tselect, tdata1, tdata2, tdata3, dcsr, dpc, dscratch0, dscratch1, `endif mcycle_lo, mcycle_hi,
//                          minstret_lo, minstret_hi, `ifdef use_MHPM mhpmcounter_lo, mhpmcounter_hi, `endif  mvendorid, marchid, mimpid, mhartid
//                          );
//endinterface: MCSR_REG_intf
//
//// ------------------------ Supervisor mode CSRs ------------------------
//interface SCSR_REG_intf;
//   // Supervisor mode Registers
//   SCSR     scsr;
//
//   modport master(output sstatus, sedeleg, `ifdef ext_N sideleg, sie, `endif stvec,
//                         scounteren,sscratch, sepc, scause, stval, `ifdef ext_N sip, `endif satp);
//
//   modport slave (input  sstatus, sedeleg, `ifdef ext_N sideleg, sie, `endif stvec,
//                         scounteren, sscratch, sepc, scause, stval, `ifdef ext_N sip, `endif satp);
//endinterface: SCSR_REG_intf
//
//// ------------------------ User mode CSRs ------------------------
//interface UCSR_REG_intf;
//   // User mode Registers
//   UCSR     ucsr;
//
//   modport master(output ucsr.ustatus, `ifdef ext_N ucsr.uie, `endif ucsr.utvec, ucsr.uscratch, ucsr.uepc, ucsr.ucause, ucsr.utval `ifdef ext_N, ucsr.uip `endif);
//   modport slave (input  ucsr.ustatus, `ifdef ext_N ucsr.uie, `endif ucsr.utvec, ucsr.uscratch, ucsr.uepc, ucsr.ucause, ucsr.utval `ifdef ext_N, ucsr.uip `endif);
//endinterface: UCSR_REG_intf

// ------------------------ CSR - EXE interface ------------------------
interface CSR_EXE_intf;
   // signals needed by EXE stage
   logic                     [RSZ-1:0] mepc;             // Machine Exception PC/ Input:   Machine Exception PC
   `ifdef ext_S
   logic                     [RSZ-1:0] sepc;             // Supervisor Exception PC
   `endif
   `ifdef ext_U
   logic                     [RSZ-1:0] uepc;             // User Exception PC
   `endif
   logic                         [1:0] mode;             // CPU mode

   // signals from EXE stage - Note: partial pipeline flush will occur when xret == TRUE & PC reloads
   logic                     [RSZ-1:0] mret;             // Machine mode return flag
   `ifdef ext_S
   logic                     [RSZ-1:0] sret;             // Supervisor Mode return flag
   `endif
   `ifdef ext_U
   logic                     [RSZ-1:0] uret;             // User Mode return flag
   `endif

   modport master(output   mepc, `ifdef ext_S sepc, `endif `ifdef ext_U uepc, `endif mode, input  `ifdef ext_S sret, `endif `ifdef ext_U uret, `endif mret);
   modport  slave(input    mepc, `ifdef ext_S sepc, `endif `ifdef ext_U uepc, `endif mode, output `ifdef ext_S sret, `endif `ifdef ext_U uret, `endif mret);

endinterface: CSR_EXE_intf


// ------------------------ CSR - WB interface ------------------------
interface CSR_WB_intf;
   logic                   [PC_SZ-1:0] trap_pc;          // Output:  trap vector handler address.
   `ifdef ext_N
   logic                               interrupt_flag;   // 1 = take an interrupt trap
   logic                     [RSZ-1:0] interrupt_cause;  // value specifying what type of interrupt
   `endif
   logic                         [1:0] mode;             // CPU mode

   modport master(output trap_pc, `ifdef ext_N interrupt_flag, interrupt_cause, `endif mode);
   modport  slave(input  trap_pc, `ifdef ext_N interrupt_flag, interrupt_cause, `endif mode);

endinterface: CSR_WB_intf
