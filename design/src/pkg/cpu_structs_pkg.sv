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

   // UNKNOWN_INSTR = 0 default until decoded
   typedef enum logic [3:0] {ILL_INSTR, ALU_INSTR, BR_INSTR, IM_INSTR, IDR_INSTR, HINT_INSTR, SYS_INSTR, CSR_INSTR, LD_INSTR, ST_INSTR, SPFP_INSTR} I_TYPE;

   typedef enum logic [2:0] {CSRRW=1,CSRRS,CSRRC,CSRRWI=5,CSRRSI,CSRRCI} CSR_TYPE;  // see funct3 bits in Zicsr table - riscv-spec.pdf p. 131

   // ----------------------------------------------- Operation types -----------------------------------------------
   // Note: size of field in DEC_2_EXE structure must be the largest size of SYS_OP_TYPE, ALU_OP_TYPE, or SPFP_OP_TYPE
   typedef enum {ECALL, EBREAK, FENCE, FENCEI, WFI} SYS_OP_TYPE;

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
   typedef enum {AM_RS1, AM_IMM, AM_RS2, AM_PC } ALU_SEL_TYPE;

   // Branch selection (i.e. sel_x or sel_y) is as follows
   typedef enum {BS_RS1, BS_IMM, BS_PC } BR_SEL_TYPE;


   // SPFP_FU selection (i.e. sel_x or sel_y) is as follows
   typedef enum {FM_RS1, FM_IMM, FM_RS2 } SPFP_SEL_TYPE;

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
      I_TYPE                  i_type;
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
      I_TYPE                  i_type;
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

   typedef enum {LD_RET, ST_RET, CSR_RET, SYS_RET, ALU_RET, BXX_RET, JAL_RET, JALR_RET, IM_RET, ID_RET, IR_RET, HINT_RET, UNK_RET
                 `ifdef ext_F FLD_RET, FST_RET, FP_RET `endif } RETIRE_TYPE;  // Thre will be a ret_cnt for each of these type of instructions
   localparam RET_SZ = $size(RETIRE_TYPE);

   typedef struct packed {                      // each entry contains count of how many instructions  of that typeretired this clock cycle
      logic                   mispredict;       // Branch Mispredict count          - not one of the faults but usefull information
      logic                   ext_irq;          // External Interrutp Request count - not one of the faults but usefull information - only 1 of these can ever occur during a clock cycle
//    logic [RET_SZ-1:0] [n-1:0] ret_cnt;  // general format to use if more than 1 instruction retires per clock cycle - where n is the number of bits needed to hold maximum count
      logic      [RET_SZ-1:0] ret_cnt;          // only 1 instruction maximum retires per clock cycle in this pipelined RV32imc... design
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
      logic       [PC_SZ-1:0] predicted_addr;
      logic       [PC_SZ-1:0] br_pc;
      I_TYPE                  i_type;
      logic       [OP_SZ-1:0] op_type;
      logic       [PC_SZ-1:0] trap_pc;          // trap vector handler address.
      logic             [1:0] mode;
      `ifdef ext_N
      logic                   interrupt_flag;   // 1 = take an interrupt trap
      logic         [RSZ-1:0] interrupt_cause;  // value specifying what type of interrupt
      `endif

      // FPR information (gets pased to MEM stage which passes it to WB stage)
      `ifdef ext_F
      logic                   Fd_wr;            // WB stage needs to know whether to write to destination register Fd
      `endif
      // GPR information (gets pased to MEM stage which passes it to WB stage)
      logic                   Rd_wr;            // WB stage needs to know whether to write to destination register Rd
      logic     [GPR_ASZ-1:0] Rd_addr;          // address of which GPR/FPR we want to Write
      logic         [RSZ-1:0] Rd_data;          // This is the write back data (produced by alu_fu, br_fu, im_fu, idr_fu, csr_fu, spfp_fu)
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
      I_TYPE                  i_type;
      logic       [OP_SZ-1:0] op_type;
      logic       [PC_SZ-1:0] trap_pc;          // trap vector handler address.
      logic             [1:0] mode;
      logic                   mio_ack_fault;

      `ifdef ext_N
      logic                   interrupt_flag;   // 1 = take an interrupt trap
      logic         [RSZ-1:0] interrupt_cause;  // value specifying what type of interrupt
      `endif

      // GPR/FPR information
      `ifdef ext_F
      logic                   Fd_wr;            // Writeback stage needs to know whether to write to single precision floating point destination register Fd
      `endif
      logic                   Rd_wr;            // Writeback stage needs to know whether to write to destination register Rd
      logic     [GPR_ASZ-1:0] Rd_addr;
      logic         [RSZ-1:0] Rd_data;          // This is the write back data (produced by alu_fu, br_fu, im_fu, idr_fu)

   } MEM_2_WB;

   // ********************************** Forwarding Info *********************************************
   typedef struct packed {
      logic                   valid;
      logic                   Rd_wr;
      logic     [GPR_ASZ-1:0] Rd_addr;
      logic         [RSZ-1:0] Rd_data;
   } FWD_GPR;

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