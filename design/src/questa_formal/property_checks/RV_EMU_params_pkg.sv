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
// Project       :  RV_FORMAL - Pre-commercial product to test RISC-V based CPUs
//               :              Currently being used to test the open-source RisKy1 CPU being developed by hdlexpress.com
// Editor        :  Notepad++
// File          :  RV_EMU_params_pkg.sv - needed by RV_EMU_core.svp emulation model
// Description   :  Property Assertions for RV32imc CPU (see PropCheck_top.sv where it includes these properties)
//               :
// Designer      :  Kirk Weedman - kirk@hdlexpress.com
// ----------------------------------------------------------------------------------------------------

package RV_EMU_params_pkg;
import cpu_params_pkg::*;
import cpu_structs_pkg::*;


typedef
 enum
   {
      _internal_error_,

      // extension C - 39 entries
      _C_ADDI4SPN_,    _C_LW_,          _C_SW_,          _C_NOP_,         _C_NOP_HINT_,
      _C_ADDI_HINT_,   _C_ADDI_,        _C_JAL_,         _C_LI_,          _C_LI_HINT_,
      _C_ADDI16SP_,    _C_LUI_,         _C_LUI_HINT_,    _C_SRLI_,        _C_SRLI_HINT_,
      _C_SRLI_HINT2_,  _C_SRAI_,        _C_SRAI_HINT_,   _C_SRAI_HINT2_,  _C_ANDI_,
      _C_SUB_,         _C_XOR_,         _C_OR_,          _C_AND_,         _C_J_,
      _C_BEQZ_,        _C_BNEZ_,        _C_SLLI_,        _C_SLLI_HINT_,   _C_SLLI_HINT2_,
      _C_LWSP_,        _C_JR_,          _C_MV_,          _C_MV_HINT_,     _C_EBREAK_,
      _C_ADD_HINT_,    _C_JALR_,        _C_ADD_,         _C_SWSP_,

      // extension F -_ 26 entries
      _FLW_,           _FSW_,           _FMADD_,         _FMSUB_,         _FNMSUB_,
      _FNMADD_,        _FADD_,          _FSUB_,          _FMUL_,          _FDIV_,
      _FSQRT_,         _FSGNJ_,         _FSGNJN_,        _FSGNJX_,        _FMIN_,
      _FMAX_,          _FCVT_W_,        _FCVT_WU_,       _FMV_X_W_,       _FEQ_,
      _FLT_,           _FLE_,           _FCLASS_,        _FCVT_S_W_,      _FCVT_S_WU_,
      _FMV_W_X_,

      // unknown and i_llegal - 4 entries
      _unknown_,       _ILLEGAL16_,     _ILLEGAL32_,     _ILLEGAL48_,


      // RV32i base - _62 entries (includes future instructions)
      _LOAD_,          _FENCE_,         _FENCE_I_,       _ADDI_,          _ADDI_HINT_,    
       _SLLI_,          _SLLI_HINT_,     _SLTI_,          _SLTI_HINT_,    _SLTIU_,         
      _SLTIU_HINT_,    _XORI_,          _XORI_HINT_,     _SRLI_,          _SRLI_HINT_,     
      _SRAI_,          _SRAI_HINT_,     _ORI_,           _ORI_HINT_,      _ANDI_,          
      _ANDI_HINT_,     _AUIPC_,         _AUIPC_HINT_,    _STORE_,         _ADD_,           
      _ADD_RES_,       _SLL_,           _SLL_RES_,       _SLT_,           _SLT_RES_,       
      _SLTU_,          _SLTU_RES_,      _XOR_,           _XOR_RES_,       _SRL_,           
      _SRL_RES_,       _OR_,            _OR_RES_,        _AND_,           _AND_RES_,       
      _SUB_,           _SUB_RES_,       _SRA_,           _SRA_RES_,       _LUI_,           
      _LUI_HINT_,      _BEQ_,           _BNE_,           _BLT_,           _BGE_,           
      _BLTU_,          _BGEU_,          _JALR_,          _JAL_,           _ECALL_,         
      _EBREAK_,        _URET_,          _SRET_,          _WFI_,           _MRET_,
      _CSR_,

      // extension M - 8 entries
      _MUL_,           _MULH_,          _MULHSU_,        _MULHU_,         _DIV_,
      _DIVU_,          _REM_,           _REMU_

   } INSTR_TYPE;

   // flags for each instruction to know when to check CPU functionality
   typedef struct packed {
      bit   pc;
      bit   Rs1_rd;
      bit   Rs1_addr;
      bit   Rs2_rd;
      bit   Rs2_addr;
      bit   gpr_wr;
      bit   gpr_addr;
      bit   gpr_data;
      bit   csr_wr;
      bit   csr_wr_data;
      bit   csr_rd;
      bit   csr_rd_data;
      bit   exceptions;    // 1 = check exception pc, tval and cause
      bit   events;
      bit   mode;
   } CHECKS;

endpackage
