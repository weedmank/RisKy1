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
// File          :  fetch.sv - interface between instruction cache and fetch stage
// Description   :  Instruction Fetch Unit - get instructions from Instruction Cache which returns
//               :  a whole cache line of data for a given address
// Designer      :  Kirk Weedman - kirk@hdlexpress.com
// ---------------------------------------------------------------------------------------------------
`timescale 1ns/100ps

import functions_pkg::*;
import logic_params_pkg::*;
import cpu_params_pkg::*;
import cpu_structs_pkg::*;
/*

      FSM
      CC_IDLE - request data (instructions, branch info) from Instruction Cache based on Next_PC
      CC_ACK  - wait and capture data (instructions, branch info) from Instruction Cache
                Find 1st branch that will be predicted as taken
                Copy instructions, starting at Next_PC until 1st branch (or end of cache line if no branch taken), into DBUF (unless full)

      NOTE: Cache returns a whole Cache Line of data for a given address.
            Assume the cache line holds 8 instructions, each are 4 bytes for a total of 32 bytes
            If the address is in the range: 0 <= addr < 32 then the same cache line of data is returned. It is up to the fetch unit
            to use the appropriate bytes from the cache line.  Example: requested address is 8. Fetch will need to get bytes 8,9,10,11
            to get that specific 32 bit instruction. In general, for a 32 byte cache line, to get an instruction starting at address N,
            the fetch unit would use the lower 5 bits as the starting location of the instruction.

*/
   // See file instr_bits.svh
   `define  ECALL       32'b0000000_00000_00000_000_00000_1110011
   `define  EBREAK      32'b0000000_00001_00000_000_00000_1110011

module fetch
(
   input    logic                      clk_in,                       // Input:
   input    logic                      reset_in,                     // Input:

   input    logic                      cpu_halt,                     // Input:   cpu is halted signal

   input    logic                      pc_reload,                    // Input:   detected invalid branch path
   input    logic                      ic_reload,                    // Input:   A STORE to L1 D$ also wrote to L1 I$ address space
   input    logic          [PC_SZ-1:0] pc_reload_addr,               // Input:   new branch path that needs to be run

   // L1 Instruction Cache signals : fetch.v requests info from the L1_icache.sv
   L1IC_intf.master                    L1IC_bus,

   // connections with next stage
   F2D_intf.master                     F2D_bus
);
   parameter   Q_DEPTH  = 2*MAX_IPCL;                                // Must be a power of 2 value for current qip, qop logic to work.
   localparam  QP_SZ    = bit_size(Q_DEPTH-1);
   localparam  QC_SZ    = bit_size(Q_DEPTH);

   logic          [PC_SZ-1:0] PC;

   // Instruction buffer (que), counters, pointers & related signals
   logic            [QC_SZ:0] qcnt, nxt_qip_cnt;
   Q_DATA       [Q_DEPTH-1:0] que, nxt_que;
   logic          [QP_SZ-1:0] qip, qop;                              // que input & output pointers
   logic          [QP_SZ-1:0] nxt_qip;                      // truncate to be same size as qip, qop
   logic          [QC_SZ-1:0] nq, nxt_qop;                      // 1 bit bigger than qop

   logic                      xfer_out;

   //-----------------------------------------------------------------------------------------------
   // 1. On reset, Start loading the queue from a requested instruction cache line
   //    Also do Branch pre decoding logic
   //-----------------------------------------------------------------------------------------------
   logic                            cl_xfer;                         // Cache Line Transfer (from I$ to here)

   Pre_Data          [MAX_IPCL-1:0] predicted;                       // One of these for each instruction in a cache line
   logic             [MAX_IPCL-1:0] bt;                              // flags to specify whether Next Address Changes

   logic [0:MAX_IPCL-1] [PC_SZ-1:0] addr;                            // One of these for each instruction in a cache line
   logic                [PC_SZ-1:0] Next_PC;
   logic                [PC_SZ-1:0] reload_addr;
   logic                            reload_flag;
   logic                            clr_rf;                          // set anytime the next state is CC_IDLE and we're not in a PC reload cycle
   logic                            save_lpa;                        // save the last_predicted_addr
   logic                            Next_ic_req;
   logic                            qfull;

   enum logic [1:0] {CC_IDLE, CC_ACK, CC_RL_ACK} cc_state, Next_cc_state;

   assign cl_xfer = L1IC_bus.req & L1IC_bus.ack;

   // Determination of next Program Counter value
   logic    [PC_SZ-1:0] last_predicted_addr, lpa;

   // FSM sequential logic and Program Counter update
   always_ff @(posedge clk_in)
   begin
      if (reset_in)                                                  // Note: A cl_xfer, during cc_state = CC_ACK, MUST be allowed to complete if a pc_reload occurs
         cc_state <= CC_IDLE;
      else
         cc_state <= Next_cc_state;

      // CPU Program Counter
      if (reset_in)
         PC <= RESET_VECTOR_ADDR;
      else
         PC <= Next_PC;

      if (reset_in)
         L1IC_bus.req <= FALSE;
      else
         L1IC_bus.req <= Next_ic_req;

      if (reset_in)
         reload_flag <= FALSE;
      else if (pc_reload | ic_reload)
         reload_flag <= TRUE;                                        // Set reload_flag TRUE when pc_reload occurs
      else if (clr_rf)
         reload_flag <= FALSE;                                       // set FALSE when PC reload has completed

      if (reset_in)
         reload_addr <= 'd0;
      else if (pc_reload | ic_reload)                                // if pc_reload or ic_reload occur in the same clock cycle, pc_reload takes precedence
         reload_addr <= pc_reload_addr;                              // capture new PC address when pc_reload occurs

      // Last Predicted Address
      if (reset_in)
         lpa <= RESET_VECTOR_ADDR;
      else if (save_lpa)
         lpa <= last_predicted_addr;
   end

   assign L1IC_bus.addr   = PC;                                     // Instruction Cache address = PC

   assign qfull = (qip == qop) & (qcnt == Q_DEPTH);

   // FSM Logic
   always_comb
   begin
      Next_PC        = PC;
      Next_cc_state  = cc_state;
      clr_rf         = FALSE;
      save_lpa       = FALSE;
      Next_ic_req    = FALSE;

      if (!reset_in)
      begin
         unique case(cc_state)
            CC_IDLE:
            begin
               Next_ic_req    = !qfull & !ic_reload;                 // request more data if the queue (instruction buffer) isn't full and there's not a ic_reload signal
               Next_PC        = reload_flag ? reload_addr : lpa;     // Next Program Counter is either from reload_addr or Last Predicted Address
               if (!qfull & !ic_reload)
                  Next_cc_state  = reload_flag ? CC_RL_ACK : CC_ACK;
            end

            CC_ACK:
            begin
               Next_ic_req    = TRUE;
               Next_PC        = PC;
               if (cl_xfer)
               begin
                  Next_ic_req    = FALSE;
                  save_lpa       = TRUE;
                  Next_cc_state  = CC_IDLE;
               end
            end

            CC_RL_ACK:
            begin
               Next_ic_req    = TRUE;
               Next_PC        = PC;
               if (cl_xfer)
               begin
                  Next_ic_req    = FALSE;
                  clr_rf         = TRUE;
                  save_lpa       = TRUE;
                  Next_cc_state  = CC_IDLE;
               end
            end
         endcase
      end
   end

   //------------------------------------------------------------------------------------------------------------------------------------------
   // RAS - Return Address Stack
   //------------------------------------------------------------------------------------------------------------------------------------------
   parameter  MAX_RAS = 8;    // must be a power of 2 for logic to work (i.e. pointers and counters "Wrap")

   localparam MR_SZ = bit_size(MAX_RAS-1);
   localparam MR2_SZ = bit_size(MAX_RAS);

   logic                [MR_SZ-1:0] ras_ptr;
   logic                [MR_SZ-1:0] nxt_ras_ptr;      // ras_ptr wrapping will work only if MAX_RAS is a power of 2 for current design
   logic  [MAX_RAS-1:0] [PC_SZ-1:0] ras, nxt_ras;     // Note: MAX_RAS should be a power of two for the current logic

   always_ff @(posedge clk_in)
   begin
      if (reset_in)
      begin
         ras_ptr  <= 'd0;
         ras      <= '{default: '0};
      end
      else
      begin
         ras_ptr  <= nxt_ras_ptr;
         ras      <= nxt_ras;
      end
   end

   //------------------------------------------------------------------------------------------------------------------------------------------
   // create predicted information that goes with each instruction written into instr_bin[]
   // valid results for predicted[] are during state CC_ACK
   //------------------------------------------------------------------------------------------------------------------------------------------
   logic               [31:0] b_imm, j_imm, i_imm;
   logic           [XLEN-1:0] i;                                                          // big enough for RV32i or RV16I instruction
   logic [MAX_IPCL-1:0] [2:0] btype;                                                      // One branch type for each instruction in the cache line

   logic                      done;

`ifdef ext_C
   logic                      overlap_flag;
   logic          [CI_SZ-1:0] overlap_instr, ov_instr;                                    // upper 16 bits of overlapping instruction
   logic          [PC_SZ-1:0] overlap_pc;
   logic                      set_overlap_flag;
   logic                      clr_overlap_flag;
   logic                      isoverlap;
`endif

   logic                [4:0] rd, rs1;
   logic                      link_rd, link_rs1;

   logic [MAX_IPCL-1:0] [2:0] instr_sz;
   logic                      is16, is32, is48;
   logic                [4:0] lower5;

   localparam  BP_SZ = bit_size(CL_LEN + CBPI)*8;                                         // last 32 bit (4 byte) instruction in a cache may overlap into next cache line by 2 bytes when ext_C enabled
   logic          [BP_SZ-1:0] bit_pos;

   logic                      cl_valid;

   assign cl_valid         =  reload_flag ? (clr_rf & cl_xfer) & !cpu_halt : cl_xfer & !cpu_halt;  // cache line data for saving to the QUE[] is available on this clock cycle;

   integer c;
   always_comb
//   always @*
   begin
      // initialize all used variables to some default value
      `ifdef SIM_DEBUG
      addr                 = '{default: 'z};                                              // fill array with Z's for easier debugging
      `else
      addr                 = '{default: '0};
      `endif
      btype                = '{default: '0};
      predicted            = '{default: '0};
      bt                   = '{default: FALSE};                                           // assume branch is not taken

      nxt_ras              = ras;

      last_predicted_addr  = PC;
      bit_pos              = PC[CL_SZ-1:0]*8;                                             // bit index to first requested instruction in the cache line

      i                    = '0;

      i_imm                = '0;
      b_imm                = '0;
      j_imm                = '0;

      rd                   = 0;
      rs1                  = 0;

      nxt_ras_ptr          = ras_ptr;

      nq                   = 0;
      nxt_qip              = qip;
      nxt_qip_cnt          = 0;
      nxt_que              = que;

      `ifdef ext_C
      set_overlap_flag     = FALSE;
      clr_overlap_flag     = FALSE;
      ov_instr             = '0;
      isoverlap            = FALSE;
      `endif

      link_rd              = FALSE;
      link_rs1             = FALSE;

      lower5               = 0;
      is16                 = FALSE;
      is32                 = FALSE;
      is48                 = FALSE;
      done                 = !cl_valid | cpu_halt;
      instr_sz             = '{default: '0};                                              // default size, in bytes, of an instruction until we know for sure what it is

      // Only process instructions if:
      // 1. A transfer from I$ occured on this cycle
      // 2. A PC reload is not occuring
      // 3. logic inside the loop determines we're not done processing this cache line of instructions
//      #1;

      for (c = 0; c < MAX_IPCL; c++)                                                      // up to MAX_IPCL instructions to process this clock cycle
      begin
         if (!done)                                                                       // whenever done gets set TRUE, no further instructions in the cache line are processed
         begin
            link_rd           = FALSE;
            link_rs1          = FALSE;

            rd                = 0;
            rs1               = 0;

            lower5            = L1IC_bus.ack_data[bit_pos +: 5];                          // 5 lower bits of either a 16 or 32 bit instruction
            is48              = lower5[4:0] == 5'b11111;
            is32              = (lower5[4:2] != 3'b111) & (lower5[1:0] == 2'b11);
            is16              = (lower5[1:0] != 2'b11);

            instr_sz[c]       = BPI;                                                      // default size is 4 bytes per instruction

            //************** 1st - determine size and branch type of each instruction

            `ifdef ext_C // Logic for Compressed instruction fetching is not yet tested and may not work - 9/1/2020
            isoverlap         = (c == 0) && overlap_flag && (overlap_pc == PC);

            // The following occurs on this clock cycle (if c==0) if an instruction "overlap" occured on the last cache line fetch
            if (isoverlap)                         // combine overlap_instr with 2 LS bytes in cache line?
            begin
               instr_sz[c] = CBPI;                                                        // only 2 bytes used to complete this RV32I instruction

               clr_overlap_flag = TRUE;                                                   // overlap completed for this cache line of instructions

               // because of overlap, isXX will likely be wrong, so define that this is a 32 bit instruction
               is48        = FALSE;
               is32        = TRUE;                                                        // process this a 32 bit instruction
               is16        = FALSE;
            end

            if (is16)                                                                     // is this a Compressed instruction (16 bit)?
            begin // RV16I
               i           = {16'b0,L1IC_bus.ack_data[bit_pos +: CI_SZ]};                 // instruction ready to be written into instr_bin[]
               instr_sz[c] = CBPI;                                                        // 2 bytes per instruction

               b_imm       = {{25{i[12]}},i[6:5],i[2],i[11:10],i[4:3],1'b0};              // offset8_1 see decode_RV.sv
               j_imm       = {{21{i[12]}},i[8],i[10:9],i[6],i[7],i[2],i[11],i[5:3],1'b0}; // see C.JAL. Also see imm11_1 in decode_RV.sv
               rd          = i[11:7];

               // determine branch type
               case ({i[15:13],i[1:0]})
                  5'b001_01:                                                              // C.JAL = JAL R1, offset[11:1]
                     btype[c] = 3'b011;
                  5'b101_01:                                                              // C.J   = JAL R0, offset[11:1]
                     btype[c] = 3'b011;
                  5'b110_01:                                                              // C.BEQZ
                     btype[c] = 3'b010;                                                   // 3'b010: branch type is conditional
                  5'b111_01:                                                              // C.BNEZ
                     btype[c] = 3'b010;                                                   // 3'b010: branch type is conditional
                  5'b100_10:
                  begin
                     if ((i[11:7] != 0) && (i[6:2] == 0))
                        btype[c] = 3'b001;                                                // Either C.JR or C.JALR - both have same btype[]
                     else
                        btype[c] = 3'b000;
                  end
                  default: btype[c] = 3'b000;
               endcase
            end
            else
            `else // ext_C not allowed
            if (is16)                                                                     // not enabled to execute 16 bit Compressed instructions!
               i = {16'b0,L1IC_bus.ack_data[bit_pos +: CI_SZ]};
            else
            `endif // ext_C

            if ( is32 )
            begin
               `ifdef ext_C
               if (isoverlap)
                  i     = {L1IC_bus.ack_data[bit_pos +: CI_SZ],overlap_instr};            // concatenated overlap_instr with lower 16 bit value from new L1IC_bus.ack_data
               else
               `endif
               i        = L1IC_bus.ack_data[bit_pos +: XLEN];                             // normal 32 bit instruction

               i_imm    = {{21{i[31]}},i[30:20]};                                         // sign extended immediate for JALR
               b_imm    = {{20{i[31]}},i[7],i[30:25],i[11:8],1'b0};                       // sign extended immediate for Bxx
               j_imm    = {{12{i[31]}},i[19:12],i[20],i[30:21],1'b0};                     // sign extended immediate for JAL
               rd       = i[11:7];
               rs1      = i[19:15];

               // determine branch type
               case (i[6:2])
                  //!!! RV32I Standard
                  5'b11000:                                                               // BEQ/BNE/BLT/BGE/BLTU/BGEU
                     btype[c] = 3'b010;                                                   // 3'b010: branch type is conditional
                  5'b11001:
                  begin
                     if (i[14:12] == 3'b000)
                        btype[c] = 3'b001;                                                // 3'b001: branch type is JALR
                  end
                  5'b11011:
                     btype[c] = 3'b011;                                                   // 3'b011: branch type is JAL
               endcase  // just ignore all other cases - btype[] will be 2'b10 by default

               `ifdef ext_U
               if (i[31:2] == 30'b0000000_00010_00000_000_00000_11100)
                  btype[c] = 3'b100;                                                      // return instructions URET
               `endif

               `ifdef ext_S
               if (i[31:2] == 30'b0001000_00010_00000_000_00000_11100)
                  btype[c] = 3'b100;                                                      // return instructions SRET
               `endif

               if (i[31:2] == 30'b0011000_00010_00000_000_00000_11100)
                  btype[c] = 3'b100;                                                      // return instructions MRET

               if (i[31:2] == 30'b0000000_00000_00000_000_00000_11100)
                  btype[c] = 3'b101;                                                      // ECALL

               if (i[31:2] == 30'b0000000_00001_00000_000_00000_11100)
                  btype[c] = 3'b101;                                                      // EBREAK
            end

            if ( is48 )                                                                   // 48 bit or larger instruction - we have a problem Houston!
               i = L1IC_bus.ack_data[bit_pos +: XLEN];                                    // just save lower 32 bits of instruction  (lowest 5 bits determine instruction size)

            //************** 2nd - determine the program counter associated with each instruction
            addr[c]  = last_predicted_addr;                                               // cache line PC value for current instruction

            //************** 3rd - determine predicted address based on each instruction
            bt[c]                = FALSE;                                                 // default is no branching
            predicted[c].addr    = addr[c] + instr_sz[c];                                 // default is to continue sequentially with next address (i.e. no branching)

            // npw check to see if we need to override(replace) the default values of bt[c] and predicted[c].addr
            unique case (btype[c])
               3'b000:                                                                    // Non Branch instruction
               begin
                  predicted[c].is_br   = FALSE;                                           // branching never takes place for non branch instructions
               end

               3'b001:                                                                    // JALR
               begin
                  predicted[c].is_br   = TRUE;                                            // This is a jump instruction, so let branch_prediction.sv know

                  // actual branch taken address is determined by contents of Rs1 + i_imm. Value of Rs1 may not be known at this time
                  predicted[c].addr    = i_imm;                                           // this is just a wild guess that assume Rs1 = R0

                  bt[c]                = TRUE;                                            // jumps are always taken
                  done                 = TRUE;                                            // We're done with any other instructions immediately after this one


                  // RAS logic is for return prediction from the end of a call
                  link_rs1 = (rs1 == 1) | (rs1 == 5);                                     // "link is true when the register is either x1 or x5"
                  link_rd  = (rd == 1)  | (rd == 5);                                      // see p 22 riscv-spec.pdf

                  // "JALR instructions should push/pop a RAS as shown in the Table 2.1"
                  case ({link_rd,link_rs1})                                               // use RISC-V hints to determine whether to push, pop or pop_then_push   see riscv-spec.pdf p 22
                     2'b01:   // pop
                        nxt_ras_ptr--;                                                    // pre decrement
                     2'b10:   // push
                     begin
                        nxt_ras[nxt_ras_ptr] = addr[c] + instr_sz[c];                     // save return address
                        nxt_ras_ptr++;                                                    // post increment
                     end
                     2'b11:   // pop then push
                     begin
                        if (rs1 != rd) // pop
                           nxt_ras_ptr--;                                                 // remove last entry on stack
                        nxt_ras[nxt_ras_ptr] = addr[c] + instr_sz[c];                     // save return address
                        nxt_ras_ptr++;                                                    // post increment
                     end
                  endcase
               end

               3'b010:                                                                    // Condition Branch  BNE/BGE/BLT...
               begin
                  // NOTE: We know the branch address at this time -> PC + b_imm, but we do NOT know if the condition is True/False
                  predicted[c].is_br   = TRUE;                                            // This is a branch instruction
                  //!!!WARNING: Good Branch Prediction logic should determine the bt[] and .addr values for these branch instructions

                  // !!!!!!!! WARNING: Good Branch Prediction logic should determine the bt[] and .addr values for these Bxx instructions !!!!!!!!

                  // !!!!!!!!! We'll make an initial guesss (until branch prediction logic is created and used here) that backward branch addresses will be taken. !!!!!!!!!!!!

                  predicted[c].addr    = b_imm[31] ? (addr[c] + b_imm) : (addr[c] + instr_sz[c]);
                  bt[c]                = b_imm[31] ? TRUE : FALSE;                        // Neg direction = TRUE: Pos direction = FALSE
               end

               3'b011:                                                                    // JAL RegD,Immed-20 The target address is given as a PC-relative instr_sz
               begin
                  predicted[c].is_br   = TRUE;
                  // NOTE: No branch prediction needed. This branch is ALWAYS taken and address is known
                  predicted[c].addr    = addr[c] + j_imm;                                 // we know the address at this time
                  bt[c]                = TRUE;                                            // jumps are always taken
                  done                 = TRUE;                                            // We're done with any other instructions immediately after this one

                  // "A JAL instruction should push the return address onto a return-address ras (RAS) only when rd=x1/x5" p 22 of risv-spec-v2.2
                  if ((rd == 1)  | (rd == 5))
                  begin
                     nxt_ras[nxt_ras_ptr] = addr[c] + instr_sz[c];                        // save return address
                     nxt_ras_ptr++;                                                       // post increment
                  end
               end

               3'b100:                                                                    // MRET,SRET,URET
               begin
                  predicted[c].is_br   = TRUE;                                            // This is a procedure return, so let branch_prediction.sv know

                  nxt_ras_ptr--;                                                          // remove last entry on stack
                  predicted[c].addr    = nxt_ras[nxt_ras_ptr];
                  bt[c]                = TRUE;
               end

               3'b101:                                                                    // ECALL,EBREAK
               begin
                  //!!!!!!! ???  is address determined by mtvec/stvec/utvec ???? trap_pc ????
                  predicted[c].addr    = 0;                                               // see csr.sv to figure this out
//                predicted[c].addr    = ((mode == 3) ? mtvec : ((mode==1) ? (stvec : utvec))); //see csr.sv
                  bt[c]                = TRUE;
               end
            endcase

            // 4th - gather necessary data collected during this cycle for placement in que[]
            last_predicted_addr  = predicted[c].addr;                                     // used in Next_PC logic. This is either a PC + 4 value for normal instructions, or a "predicted" address for branch instructions

            nq = nxt_qip;
            
            nxt_que[nq].ipd.instruction  = i;
            nxt_que[nq].ipd.pc           = addr[c];
            nxt_que[nq].predicted_addr   = predicted[c].addr;
            nq++;                                                                         // increment que input pointer. size must be 1 bit larger than nxt_qip.
            nxt_qip = nq[QP_SZ-1:0];                                                      // pointer wrapping logic
            
            nxt_qip_cnt++;                                                                // number of instructions being saved this clock cycle
            if (nxt_qip == qop)
               done = TRUE;                                                               // queue is full - can't save any more

            bit_pos += instr_sz[c]*8;                                                     // address in current cache line of next instruction (this value could get as large as CL_SZ + 2)

            if (bt[c])                                                                    // if a branch is taken then stop sequential fetching (PC + instr_sz) and start with new predicted address
               done  = TRUE;

            `ifndef ext_C
            if (is16)
               done = TRUE;                                                               // CPU does not support 16 bit compressed instructions unless ext_C is defined
            `endif

            if (is48)
               done  = TRUE;

            if (is32 && (bit_pos >= (CL_LEN*8)))                                          // is next instruction in next cache line
            begin
               done  = TRUE;
               `ifdef ext_C
               if (bit_pos != (CL_LEN*8))                                                 // this 4 byte instruciton is split across a cache line boundary
               begin
                  set_overlap_flag  = TRUE;                                               // only 32bit instructions can overlap into next cache line
                  ov_instr = L1IC_bus.ack_data[(CL_LEN*8 - CI_SZ) +: CI_SZ];              // record lower 16 bits of overlapping instruction
               end
               `endif
            end

            `ifdef ext_C
            if (is16 && (bit_pos == (CL_LEN*8)))                                          // is next instruction in next cache line
               done  = TRUE;
            `endif
         end // if (!done)
//#0.1;
      end // for (c = 0; ....
   end

   //------------------------------------------------------------------------------------------------------------------------------------------
   // Data & Control logic to Decode Stage
   //------------------------------------------------------------------------------------------------------------------------------------------
   assign F2D_bus.valid  = (qcnt != 0);

   assign xfer_out   = F2D_bus.valid & F2D_bus.rdy;

   `ifdef SIM_DEBUG
   assign F2D_bus.data.ipd              = xfer_out ? que[qop].ipd : 'bz;                  // nothing should fail when all data structure values are 'bz (i.e. no transfers being made)
   assign F2D_bus.data.predicted_addr   = xfer_out ? que[qop].predicted_addr : 'bz;
   `else
   assign F2D_bus.data.ipd              = que[qop].ipd;
   assign F2D_bus.data.predicted_addr   = que[qop].predicted_addr;
   `endif

   //------------------------------------------------------------------------------------------------------------------------------------------
   // Update pointers
   //------------------------------------------------------------------------------------------------------------------------------------------
   assign nxt_qop = qop + 1'd1;
   
   always_ff @(posedge clk_in)
   begin
      if (reset_in | pc_reload | ic_reload)
         qcnt <= 'd0;
      else if (xfer_out)                                                                  // update qcnt whenever an instruction gets transfered to the Decode Stage
         qcnt <= qcnt + nxt_qip_cnt - 1'd1;                                               // include any incoming data in the calculation
      else
         qcnt <= qcnt + nxt_qip_cnt;                                                      // update to qcnt whenever no output data gets transfered to the Decode Stage

      if (reset_in | pc_reload | ic_reload)
         qip <= 'd0;
      else
         qip <= nxt_qip;                                                                  // Circular buffer pointer. QP_SZ must be a power of 2 value!

      if (reset_in | pc_reload | ic_reload)
         qop <= 'd0;
      else if (xfer_out)
         qop <= nxt_qop[QP_SZ-1:0];                                                       // Circular buffer pointer. QP_SZ must be a power of 2 value!

      if (reset_in | pc_reload | ic_reload)
         que <= 'd0;
      else
         que <= nxt_que;

      `ifdef ext_C
      if (reset_in | pc_reload | ic_reload)
      begin
         overlap_flag   <= FALSE;
         overlap_instr  <= '0;
         overlap_pc     <= 0;
      end
      else if (set_overlap_flag)                                                          // set has priority over clear in case both occur in same clock cycle (which is OK)
      begin
         overlap_flag   <= TRUE;
         overlap_instr  <= ov_instr;
         overlap_pc     <= {PC>>CL_SZ,{CL_SZ{1'b0}}}+CL_LEN;                              // what next address should be if there's an overlapping instruction
      end
      else if (clr_overlap_flag)
      begin
         overlap_flag   <= FALSE;
         overlap_instr  <= 0;
         overlap_pc     <= 0;
      end
      `endif
   end


   //-------------- Debugging: disassemble instructions that will go into que[] at end of this clock cycle ---------------
   `ifdef SIM_DEBUG
   genvar d;
   string   i_str[0:MAX_IPCL-1];
   string   pc_str[0:MAX_IPCL-1];
   generate
      for (d = 0; d < MAX_IPCL; d++)
         disasm nxt_que_dis (ASSEMBLY,nxt_que[d].ipd,i_str[d],pc_str[d]);                 // disassemble each instruction
   endgenerate
   `endif
   //---------------------------------------------------------------------------------------------------------------------

endmodule

// Theory of operation
//
// The largest (2nd) always_comb procedural block is mainly used to do the following:
// 1. Determine contents of the instruction queue (que) and instruction queue input pointer (qip)
//    A. Based on the signals of the current clock cycle, determine what will be put into que on the next clock cycle. Note that
//       nxt_que and nxt_qip are initially set to que, qip at the beginnning of the always_comb block.  If logic in the "for" loop
//       does not override nxt_que, nxt_qip, then que. nxt_qip will normally stay the same on the next clock cycle - see last always_ff block
//       However if a reset, pc_reload or ic_reload occur, then they get set back to 0.
//    B. The "for" loop is used to decipher an incoming cache line of data from the instruction cache when cl_xfer is TRUE. Notice that
//       variable done is set TRUE if cl_xfer is false (nothinng to process).  done = TRUE causes the "for" loop to do nothing and thus
//       the que, qip will not get updated if cl_xfer == FALSE during the current clock cycle. Same thing occurs if the cpu is in halt mode (cpu_halt)
//    C. If this is a clock cycle where a transfer of data from the instruction cache occurs (cl_xfer) then the "for" loop becomes active trying
//       to determine if each instruction is either a 32 bit instruction or 16 bit instruction by looking at the lower two bits of the instruction
//       It also "pre-decodes" to see if the instruction is some sort of branch instruction so that branch prediction info can be created and
//       placed into the que along with the instruction AND to determine which instructions will next be fetched from the instruction cache.