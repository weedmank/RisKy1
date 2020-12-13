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
// File          :  cpu_structs_pkg.sv - structures and other data types used in the design
// Description   :  various data structures used in various modules
//               :
// Designer      :  Kirk Weedman - kirk@hdlexpress.com
// ----------------------------------------------------------------------------------------------------

package cpu_structs_pkg;
import cpu_params_pkg::*;

   typedef int unsigned u_int;

   // Instruction Group type
   typedef enum logic [3:0] {ILL_INSTR, ALU_INSTR, BR_INSTR, IM_INSTR, IDR_INSTR, HINT_INSTR, SYS_INSTR, CSR_INSTR, LD_INSTR, ST_INSTR, SPFP_INSTR} IG_TYPE;

   typedef enum logic [2:0] {CSRRW=1,CSRRS,CSRRC,CSRRWI=5,CSRRSI,CSRRCI} CSR_TYPE;  // see funct3 bits in Zicsr table - riscv-spec.pdf p. 131

   // ----------------------------------------------- Operation types -----------------------------------------------
   // Note: size of field in DEC_2_EXE structure must be the largest size of SYS_OP_TYPE, ALU_OP_TYPE, or SPFP_OP_TYPE
   typedef enum logic [2:0] {ECALL, EBREAK, FENCE, FENCEI, WFI} SYS_OP_TYPE;

   // ALU instruction encodings
   typedef enum logic [3:0] {A_ADD, A_SUB, A_AND, A_OR, A_XOR, A_SLL, A_SRL, A_SRA, A_SLT, A_SLTU} ALU_OP_TYPE;

   // Branch instruction encodings
   typedef enum logic [2:0] {B_ADD, B_JAL, B_JALR, B_URET, B_SRET, B_MRET, B_C} BR_OP_TYPE;

   // Integer Division/Remainder instruction encodings
   typedef enum logic [1:0] {DIV, DIVU, REM, REMU} IDR_OP_TYPE;

   // Integer Multiplication instruction encodings
   typedef enum logic [1:0] {MUL, MULH, MULHSU, MULHU} IM_OP_TYPE;

   `ifdef ext_F
   // Single Precision Floating Point instruction encodings
   typedef enum logic [4:0]
      { F_LW, F_SW, F_MADD, F_MSUB, F_NMSUB, F_NMADD, F_ADD, F_SUB, F_MUL, F_DIV, F_SQRT, F_SGNJ, F_SGNJN, F_SGNJX,
        F_MIN, F_MAX, F_CVTW, F_CVTWU, F_MVXW, F_EQ, F_LT, F_LE, F_CLASS, F_CVSW, F_CVSWU, F_MVWX
      } SPFP_OP_TYPE;

   localparam SPFP_OP_SZ   = $bits(SPFP_OP_TYPE);
   `endif

   localparam ALU_OP_SZ    = $bits(ALU_OP_TYPE);
   localparam BR_OP_SZ     = $bits(BR_OP_TYPE);
   localparam IDR_OP_SZ    = $bits(IDR_OP_TYPE);
   localparam IM_OP_SZ     = $bits(IM_OP_TYPE);

   localparam OP1_SZ = (ALU_OP_SZ > BR_OP_SZ)  ? ALU_OP_SZ : BR_OP_SZ;
   localparam OP2_SZ = (OP1_SZ    > IDR_OP_SZ) ? OP1_SZ    : IDR_OP_SZ;
   localparam OP3_SZ = (OP2_SZ    > IM_OP_SZ)  ? OP2_SZ    : IM_OP_SZ;
   `ifndef ext_F
   localparam OP_SZ  = OP3_SZ;
   `else
   localparam OP_SZ  = (OP3_SZ > SPFP_OP_SZ) ? OP3_SZ : SPFP_OP_SZ;
   `endif

   // ----------------------------------------------- Selection types -----------------------------------------------
   // ALU selection (i.e. sel_x or sel_y) is as follows
   typedef enum logic [1:0] {AM_RS1, AM_IMM, AM_RS2, AM_PC } ALU_SEL_TYPE;

   // Branch selection (i.e. sel_x or sel_y) is as follows
   typedef enum logic [1:0] {BS_RS1, BS_IMM, BS_PC } BR_SEL_TYPE;


   // SPFP_FU selection (i.e. sel_x or sel_y) is as follows
   typedef enum logic [1:0] {FM_RS1, FM_IMM, FM_RS2 } SPFP_SEL_TYPE;

   typedef union packed {
      ALU_SEL_TYPE   alu_sel;
      BR_SEL_TYPE    br_sel;
      SPFP_SEL_TYPE  spfp_sel;
   } SEL_TYPE;
//------------------------------------------ structures initialized in fetch.sv -------------------------------------------
   typedef struct packed {
      logic        [XLEN-1:0] instruction;
      logic       [PC_SZ-1:0] pc;
   } IP_Data;

//------------------------------------------ Predecode data structure for fetch.sv ------------------------------------------
   typedef struct packed {
      logic       [PC_SZ-1:0] addr;                // Branch prediction address for TAKEN or NOT_TAKEN
      logic                   is_br;               // 1 = this is a branch instruction
   } Pre_Data;

   typedef struct packed {
      IP_Data                 ipd;
      logic       [PC_SZ-1:0] predicted_addr;
   } Q_DATA;

   typedef struct packed {
      IP_Data                 ipd;
      logic       [PC_SZ-1:0] predicted_addr;
   } FET_2_DEC;
//------------------------------------------ structures initialized in decode.sv ------------------------------------------
   typedef struct packed {
      logic                   Fs1_rd;
      logic                   Fs2_rd;
      logic                   Fd_wr;
      logic                   Rs1_rd;
      logic                   Rs2_rd;
      logic                   Rd_wr;
      IG_TYPE                 ig_type;
      SEL_TYPE                sel_x;
      SEL_TYPE                sel_y;
      logic       [OP_SZ-1:0] op;
      logic                   ci;               // compressed instruction
      logic         [RSZ-1:0] imm;
   } ROM_Data;

   typedef struct packed {
      IP_Data                 ipd;              // pass instruction and program counter
      logic       [PC_SZ-1:0] predicted_addr;
      logic                   Rs1_rd;
      logic                   Rs2_rd;
      logic                   Rd_wr;
      `ifdef ext_F
      logic                   Fs1_rd;
      logic                   Fs2_rd;
      logic                   Fd_wr;
      `endif
      IG_TYPE                 ig_type;
      SEL_TYPE                sel_x;
      SEL_TYPE                sel_y;
      logic       [OP_SZ-1:0] op;
      logic                   ci;               // 1 = compressed 16-bit instruction, 0 = 32 bit instruction
      logic         [RSZ-1:0] imm;
      logic             [2:0] funct3;
      logic     [GPR_ASZ-1:0] Rs2_addr;
      logic     [GPR_ASZ-1:0] Rs1_addr;
      logic     [GPR_ASZ-1:0] Rd_addr;
   } DEC_2_EXE;

   // ---------------------------------------------------------------------------------------------------------------
   // see mem.sv
   typedef struct packed {
      logic       [PC_SZ-1:0] pc;               // new program counter due to exception
      logic         [RSZ-1:0] tval;             // trap value (information)
      logic         [RSZ-1:0] cause;            // 0 - 15, 2 = illegal instruction
      logic                   flag;             // 1 = take an exception trap
   } EXCEPTION;

   // There will be a ret_cnt for each of these type of instructions
   typedef enum {LD_RET, ST_RET, CSR_RET, SYS_RET, ALU_RET, BXX_RET, JAL_RET, JALR_RET, IM_RET, ID_RET, IR_RET, HINT_RET, `ifdef ext_F FLD_RET, FST_RET, FP_RET, `endif  UNK_RET} RETIRE_TYPE;

   // Verilog
//   `ifdef MODELSIM
      localparam RET_SZ = 15;                   // must change depending on number of RETIRE_TYPE entries!!!!!!!!!!!!!
//   `else
//      localparam RET_SZ = RETIRE_TYPE.num();    // Modelsim 2020.1 and lower can't handle this
//   `endif
   
   typedef struct packed {                      // each entry contains count of how many instructions  of that typeretired this clock cycle
      logic                   mispredict;       // Branch Mispredict count          - not one of the faults but usefull information
      logic                   ext_irq;          // External Interrutp Request count - not one of the faults but usefull information - only 1 of these can ever occur during a clock cycle
//    logic   [RET_SZ:0] [n-1:0] ret_cnt;       // general format to use if more than 1 instruction retires per clock cycle - where n is the number of bits needed to hold maximum count
      logic        [RET_SZ:0] ret_cnt;          // only 1 instruction maximum retires per clock cycle in this pipelined RV32imc... design
      logic                   e_flag;           // e_flag = 1 = the type of problem that occured with this instrucion is specified in e_cause
      logic             [3:0] e_cause;          // 0 = Instruction Address Misaligned
                                                // 1 = Instruction Access Fault
                                                // 2 = Illegal Instruction
                                                // 3 = Environment Break
                                                // 4 = Load Address Misaligned
                                                // 5 = Load Access Fault
                                                // 6 = Store Address Misaligned
                                                // 7 = Store Access Fault
                                                // 8 = User ECALL
                                                // 9 = Supervisor ECALL
                                                // 10 = Hypervsor ECALL - not used in this design
                                                // 11 = Machine ECALL
   } EVENTS;

   typedef struct packed {
      // information to be consumed by the MEM stage
      IP_Data                 ipd;              // pass instruction and program counter for debugging purposes
      logic       [PC_SZ-1:0] ls_addr;
      logic         [RSZ-1:0] st_data;
      logic             [2:0] size;
      logic                   zero_ext;         // 1 = LBU or LHU
      logic                   inv_flag;         // invalidate flag
      logic                   is_ld;            // 1 = Read from System Memory
      logic                   is_st;            // 1 = Write to System Memory
      logic                   mis;
      logic                   mispre;
      logic                   ci;               // 1 = compressed 16-bit instruction, 0 = 32 bit instruction
      logic       [PC_SZ-1:0] br_pc;
      IG_TYPE                 ig_type;
      logic       [OP_SZ-1:0] op_type;
      logic             [1:0] mode;             // mode can change on any clock cycle, but we want to pass value associated with current instruction
      `ifdef ext_N
      logic                   interrupt_flag;   // 1 = take an interrupt trap
      logic         [RSZ-1:0] interrupt_cause;  // value specifying what type of interrupt
      `endif
      logic       [PC_SZ-1:0] trap_pc;          // Output:  trap vector handler address.

      // GPR/FPR information (gets pased to MEM stage which passes it to WB stage)
      `ifdef ext_F
      logic                   Fd_wr;            // WB stage needs to know whether to write to destination register Fd
      `endif
      logic                   Rd_wr;            // WB stage needs to know whether to write to destination register Rd
      logic     [GPR_ASZ-1:0] Rd_addr;          // address of which GPR/FPR we want to Write
      logic         [RSZ-1:0] Rd_data;          // This is the write back data (produced by alu_fu, br_fu, im_fu, idr_fu, csr_fu, spfp_fu)
      // CSR information (gets pased to MEM stage which passes it to WB stage)
      logic                   csr_wr;           // WB stage needs to know whether to write to CSR
      logic            [11:0] csr_addr;         // address of which CSR we want to Write
      logic         [RSZ-1:0] csr_wr_data;      // This is the write back data (produced by csr_fu)
      logic         [RSZ-1:0] csr_fwd_data;     // This data must used in forwarding, not csr_wr_data
   } EXE_2_MEM;


   typedef struct packed {
      // information to be consumed by the MEM stage
      IP_Data                 ipd;              // pass instruction and program counter for debugging purposes
      logic       [PC_SZ-1:0] ls_addr;
      logic                   inv_flag;         // invalidate flag
      logic                   mis;
      logic                   mispre;
      logic                   ci;               // 1 = compressed 16-bit instruction, 0 = 32 bit instruction
      logic       [PC_SZ-1:0] br_pc;
      IG_TYPE                 ig_type;
      logic       [OP_SZ-1:0] op_type;
      logic                   mio_ack_fault;
      logic             [1:0] mode;
      `ifdef ext_N
      logic                   interrupt_flag;   // 1 = take an interrupt trap
      logic         [RSZ-1:0] interrupt_cause;  // value specifying what type of interrupt
      `endif
      logic       [PC_SZ-1:0] trap_pc;          // Output:  trap vector handler address.

      // GPR/FPR information
      `ifdef ext_F
      logic                   Fd_wr;            // Writeback stage needs to know whether to write to single precision floating point destination register Fd
      `endif
      logic                   Rd_wr;            // Writeback stage needs to know whether to write to destination register Rd
      logic     [GPR_ASZ-1:0] Rd_addr;
      logic         [RSZ-1:0] Rd_data;          // This is the write back data (produced by alu_fu, br_fu, im_fu, idr_fu)
      // CSR information (gets pased to MEM stage which passes it to WB stage)
      logic                   csr_wr;           // WB stage needs to know whether to write to CSR
      logic            [11:0] csr_addr;         // address of which CSR we want to Write
      logic         [RSZ-1:0] csr_wr_data;      // This is the write back data (produced by csr_fu)
      logic         [RSZ-1:0] csr_fwd_data;     // This data must used in forwarding, not csr_wr_data
   } MEM_2_WB;

   // ********************************** Forwarding Info *********************************************
   typedef struct packed {
      logic                   valid;
      logic                   Rd_wr;
      logic     [GPR_ASZ-1:0] Rd_addr;
      logic         [RSZ-1:0] Rd_data;
   } FWD_GPR;

   typedef struct packed {
      logic                   valid;
      logic                   csr_wr;
      logic            [11:0] csr_addr;
      logic         [RSZ-1:0] csr_data;
   } FWD_CSR;

   `ifdef ext_F
   typedef struct packed {
      logic                   valid;
      logic                   Fd_wr;
      logic     [FPR_ASZ-1:0] Fd_addr;
      logic        [FLEN-1:0] Fd_data;
   } FWD_FPR;
   `endif

   // ---------------------------------------------------------------------------------------------------------------
   // structures related to Memory, L1 D$ and L1 I$
   typedef struct packed {
      logic                   rd;               // is_ld
      logic                   wr;               // is_st
      logic       [PC_SZ-1:0] rw_addr;          // ls_addr - Load/Store Address
      logic         [RSZ-1:0] wr_data;          // st_data - Store data
      logic             [2:0] size;             // size in bytes -> 1 = 8 bit, 2 = 16 bit, 4 = 32 bit Load/Store
      logic                   zero_ext;         // 1 = Zero Extend
      logic                   inv_flag;         // invalidate flag
   } L1DC_Req_Data;

   typedef struct packed {
      logic                   rw;               // read = 1, write = 0
      logic [PC_SZ-CL_SZ-1:0] rw_addr;          // rw_addr - cache line address
      logic    [CL_LEN*8-1:0] wr_data;          // wr_data - cache line of data to be stored if rw = 0
   } ARB_Data;


   typedef struct packed {
      logic                   ls_access_fault;
      IP_Data                 ipd;
      logic                   is_ld;
   } ACC_FAULT;

   // ---------------------------------------------------------------------------------------------------------------
   // structures related to L/S Queue data from MEM stage that needs to be saved in the L/S Queue
   typedef struct packed {
      logic       [PC_SZ-1:0] ls_addr;
      logic         [RSZ-1:0] st_data;
      logic             [2:0] size;
      logic                   zero_ext;         // 1 = LBU or LHU
      logic                   inv_flag;
      logic                   is_ld;
      logic                   is_st;
      logic                   mis;              // misalignment
   } MEM_LS_Data;

`ifdef add_LSQ
   typedef struct packed {
      logic       [PC_SZ-1:0] addr;
      logic         [RSZ-1:0] data;
      logic             [2:0] size;
      logic                   zero_ext;         // 1 = LBU or LHU
      logic                   inv_flag;
      logic                   is_ld;            // 1 = Load, 0 = Store
      logic                   completed;
      logic                   fault;            // Load/Store fault occured
      logic                   mis;              // Load/store misalignment
   } LSQ_Data;
`endif


   // 12'h300 = 12'b0000_0000_0000  ustatus     (read-write)  user mode
   //  31        22   21  20   19   18   17   16:15 14:13 12:11  10:9    8    7     6     5     4      3     2     1    0
   // {sd, 8'b0, tsr, tw, tvm, mxr, sum, mprv,   xs,   fs,  mpp, 2'b0,  spp, mpie, 1'b0, spie, upie,  mie, 1'b0,  sie, uie};
   typedef struct packed {
      logic                   sd;
      logic             [7:0] WPRI_8;
      logic                   tsr;
      logic                   tw;
      logic                   tvm;
      logic                   mxr;
      logic                   sum;
      logic                   mprv;
      logic             [1:0] xs;
      logic             [1:0] fs;
      logic             [1:0] mpp;
      logic             [1:0] WPRI_2;
      logic                   spp;
      logic                   mpie;
      logic                   WPRI_1;
      logic                   spie;
      logic                   upie;
      logic                   mie;
      logic                   WPRI;
      logic                   sie;
      logic                   uie;
   } MSTATUS_SIGS;

   // 12'h304 = 12'b0011_0000_0100  mie                           (read-write)
   //  31:12   11    10    9     8     7     6     5     4     3     2     1     0
   // {20'b0, meie, WPRI, seie, ueie, mtie, WPRI, stie, utie, msie, WPRI, ssie, usie};
   // Read Only bits of 32'hFFFF_F444;  // Note: bits 31:12, 10, 6, 2 are not writable and are "hardwired" to 0 (init value = 0 at reset)
   typedef struct packed {
      logic            [19:0] WPRI_20;
      logic                   meie;
      logic                   WPRI_1;
      logic                   seie;
      logic                   ueie;
      logic                   mtie;
      logic                   WPRI;
      logic                   stie;
      logic                   utie;
      logic                   msie;
      logic                   WPRI1;
      logic                   ssie;
      logic                   usie;
   } MIE_SIGS;

   // ------------------------------ Machine Interrupt Pending bits
   // 12'h344 = 12'b0011_0100_0100  mip                           (read-write)  machine mode
   //  31:12   11    10    9     8     7     6     5     4     3     2     1     0
   // {20'b0, meip, 1'b0, seip, ueip, mtip, 1'b0, stip, utip, msip, 1'b0, ssip, usip};
   typedef struct packed {
      logic            [19:0] WPRI_20;
      logic                   meip;
      logic                   WPRI_1;
      logic                   seip;
      logic                   ueip;
      logic                   mtip;
      logic                   WPRI;
      logic                   stip;
      logic                   utip;
      logic                   msip;
      logic                   WPRI1;
      logic                   ssip;
      logic                   usip;
   } MIP_SIGS;


   // ------------------------------ Supervisor Interrupt Pending bits
   // 12'h144 = 12'b0011_0100_0100  mip                           (read-write)  machine mode
   //  31:12   11    10    9     8     7     6     5     4     3     2     1     0
   // {20'b0, 1'b0, 1'b0, seip, ueip, 1'b0, 1'b0, stip, utip, 1'b0, 1'b0, ssip, usip};
   typedef struct packed {
      logic            [21:0] WPRI_22;
      logic                   seip;
      logic                   ueip;
      logic             [1:0] WPRI2;
      logic                   stip;
      logic                   utip;
      logic             [1:0] WPRI_2;
      logic                   ssip;
      logic                   usip;
   } SIP_SIGS;

   // ------------------------------ Supervisor Interrupt Pending bits
   // 12'h144 = 12'b0011_0100_0100  mip                           (read-write)  machine mode
   //  31:12   11    10    9     8     7     6     5     4     3     2     1     0
   // {20'b0, 1'b0, 1'b0, 1'b0, ueip, 1'b0, 1'b0, 1'b0, utip, 1'b0, 1'b0, 1'b0, usip};
   typedef struct packed {
      logic            [22:0] WPRI_23;
      logic                   ueip;
      logic             [2:0] WPRI3;
      logic                   utip;
      logic             [2:0] WPRI_3;
      logic                   usip;
   } UIP_SIGS;

   // ------------------------ Machine mode CSRs ------------------------
   typedef struct packed {
      MSTATUS_SIGS                           mstatus;          // 12'h300
      logic                        [RSZ-1:0] misa;             // 12'h301
      `ifdef ext_S   // "In systems with S-mode, the medeleg and mideleg registers must exist,..." see p. 28 riscv-privileged.pdf, csr_wr_mach.svh
      logic                        [RSZ-1:0] medeleg;          // 12'h302
         `ifdef ext_N
          logic                    [RSZ-1:0] mideleg;          // 12'h303
          `endif
      `elsif ext_U
         logic                     [RSZ-1:0] medeleg;          // 12'h302
         `ifdef ext_N
         logic                     [RSZ-1:0] mideleg;          // 12'h303
         `endif
      `endif
      `ifdef ext_N
      MIE_SIGS                               mie;              // 12'h304
      `endif
      logic                        [RSZ-1:0] mtvec;            // 12'h305
      logic                        [RSZ-1:0] mcounteren;       // 12'h306
      logic                        [RSZ-1:0] mcountinhibit;    // 12'h320
      `ifdef use_MHPM
      logic   [NUM_MHPM-1:0] [EV_SEL_SZ-1:0] mhpmevent;        // 12'h323 - 12'h33F, mhpmevent3 - mhpmevent31
      `endif

      logic                        [RSZ-1:0] mscratch;         // 12'h340
      logic                      [PC_SZ-1:0] mepc;             // 12'h341
      logic                        [RSZ-1:0] mcause;           // 12'h342
      logic                        [RSZ-1:0] mtval;            // 12'h343
      `ifdef ext_N
      MIP_SIGS                               mip;              // 12'h344
      `endif

      `ifdef USE_PMPCFG
      logic                        [RSZ-1:0] pmpcfg0;          // 12'h3A0
      logic                        [RSZ-1:0] pmpcfg1;          // 12'h3A1
      logic                        [RSZ-1:0] pmpcfg2;          // 12'h3A2
      logic                        [RSZ-1:0] pmpcfg3;          // 12'h3A3
      `endif

      `ifdef PMP_ADDR0
      logic                        [RSZ-1:0] pmpaddr0;         // 12'h3B0
      `endif
      `ifdef PMP_ADDR1
      logic                        [RSZ-1:0] pmpaddr1;         // 12'h3B1
      `endif
      `ifdef PMP_ADDR2
      logic                        [RSZ-1:0] pmpaddr2;         // 12'h3B2
      `endif
      `ifdef PMP_ADDR3
      logic                        [RSZ-1:0] pmpaddr3;         // 12'h3B3
      `endif
      `ifdef PMP_ADDR4
      logic                        [RSZ-1:0] pmpaddr4;         // 12'h3B4
      `endif
      `ifdef PMP_ADDR5
      logic                        [RSZ-1:0] pmpaddr5;         // 12'h3B5
      `endif
      `ifdef PMP_ADDR6
      logic                        [RSZ-1:0] pmpaddr6;         // 12'h3B6
      `endif
      `ifdef PMP_ADDR7
      logic                        [RSZ-1:0] pmpaddr7;         // 12'h3B7
      `endif
      `ifdef PMP_ADDR8
      logic                        [RSZ-1:0] pmpaddr8;         // 12'h3B8
      `endif
      `ifdef PMP_ADDR9
      logic                        [RSZ-1:0] pmpaddr9;         // 12'h3B9
      `endif
      `ifdef PMP_ADDR10
      logic                        [RSZ-1:0] pmpaddr10;        // 12'h3BA
      `endif
      `ifdef PMP_ADDR11
      logic                        [RSZ-1:0] pmpaddr11;        // 12'h3BB
      `endif
      `ifdef PMP_ADDR12
      logic                        [RSZ-1:0] pmpaddr12;        // 12'h3BC
      `endif
      `ifdef PMP_ADDR13
      logic                        [RSZ-1:0] pmpaddr13;        // 12'h3BD
      `endif
      `ifdef PMP_ADDR14
      logic                        [RSZ-1:0] pmpaddr14;        // 12'h3BE
      `endif
      `ifdef PMP_ADDR15
      logic                        [RSZ-1:0] pmpaddr15;        // 12'h3BF
      `endif

      `ifdef add_DM
      logic                        [RSZ-1:0] tselect;          // 12'h7A0
      logic                        [RSZ-1:0] tdata1;           // 12'h7A1
      logic                        [RSZ-1:0] tdata2;           // 12'h7A2
      logic                        [RSZ-1:0] tdata3;           // 12'h7A3
      logic                        [RSZ-1:0] dcsr;             // 12'h7B0
      logic                        [RSZ-1:0] dpc;              // 12'h7B1
      logic                        [RSZ-1:0] dscratch0;        // 12'h7B2
      logic                        [RSZ-1:0] dscratch1;        // 12'h7B3
      `endif

      logic                        [RSZ-1:0] mcycle_lo;        // 12'hB00
      logic                        [RSZ-1:0] mcycle_hi;        // 12'hB80
      logic                        [RSZ-1:0] minstret_lo;      // 12'hB02
      logic                        [RSZ-1:0] minstret_hi;      // 12'hB82

      `ifdef use_MHPM
      logic         [NUM_MHPM-1:0] [RSZ-1:0] mhpmcounter_lo;   // 12'hB03 - 12'B1F
      logic         [NUM_MHPM-1:0] [RSZ-1:0] mhpmcounter_hi;   // 12'hB83 - 12'B9F
      `endif

      logic                        [RSZ-1:0] mvendorid;        // 12'hF11
      logic                        [RSZ-1:0] marchid;          // 12'hF12
      logic                        [RSZ-1:0] mimpid;           // 12'hF13
      logic                        [RSZ-1:0] mhartid;          // 12'hF14
   } MCSR;

   // ------------------------ Supervisor mode CSRs ------------------------
   // Supervisor mode Registers
   typedef struct packed {
      logic                        [RSZ-1:0] sstatus;          // 12'h100
      logic                        [RSZ-1:0] sedeleg;          // 12'h102
      `ifdef ext_N
      logic                        [RSZ-1:0] sideleg;          // 12'h103
      logic                        [RSZ-1:0] sie;              // 12'h104
      `endif
      logic                        [RSZ-1:0] stvec;            // 12'h105
      logic                        [RSZ-1:0] scounteren;       // 12'h106
      logic                        [RSZ-1:0] sscratch;         // 12'h140
      logic                      [PC_SZ-1:0] sepc;             // 12'h141
      logic                        [RSZ-1:0] scause;           // 12'h142
      logic                        [RSZ-1:0] stval;            // 12'h143
      `ifdef ext_N
      SIP_SIGS                               sip;              // 12'h144
      `endif
      logic                        [RSZ-1:0] satp;             // 12'h180
   } SCSR;

   // ------------------------ User mode CSRs ------------------------
   // User mode Registers
   typedef struct packed {
      logic                        [RSZ-1:0] ustatus;          // 12'h000
      `ifdef ext_N
      logic                        [RSZ-1:0] uie;              // 12'h004
      `endif
      logic                        [RSZ-1:0] utvec;            // 12'h005
      logic                        [RSZ-1:0] uscratch;         // 12'h040
      logic                      [PC_SZ-1:0] uepc;             // 12'h041
      logic                        [RSZ-1:0] ucause;           // 12'h042
      logic                        [RSZ-1:0] utval;            // 12'h043
      `ifdef ext_N
      UIP_SIGS                               uip;              // 12'h044
      `endif
   } UCSR;

/*
   Register     Alias      Description                      Saved by
   x0           zero       Zero
   x1           ra         Return address                   Caller
   x2           sp         Stack pointer                    Callee
   x3           gp         Global pointer
   x4           tp         Thread pointer
   x5–7         t0–2       Temporary                        Caller
   x8           s0/fp      Saved register / frame pointer   Callee
   x9           s1         Saved register                   Callee
   x10–17       a0–a7      Arguments and return values      Caller
   x18–27       s2–11      Saved registers                  Callee
   x28–31       t3–6       Temporary                        Caller
*/

endpackage