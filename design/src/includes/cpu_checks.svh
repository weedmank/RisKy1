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
// File          :  cpu_checks.svh
// Description   :  use in RisKy1_core.sv to check CPU configuration parameters
//               :
// Designer      :  Kirk Weedman - kirk@hdlexpress.com
// ----------------------------------------------------------------------------------------------------
   generate
      `ifdef ext_N
         `ifndef ext_U
            $error ("Must define 'ext_U' in order to use ext_N");
         `endif
      `endif
   
      `ifdef ext_F
         `ifndef ext_Zicsr
            $error ("The F extension depends on the 'Zicsr' extension for control and status register access."); // The F extension depends on the â€œZicsrâ€? extension for control and status register access.
         `endif
      `endif
   
      `ifdef use_MHPM_CNTRS
      if (NUM_MHPM == 0)                                                      $error ("use_MHPM_CNTRS is defined but NUM_MHPM is still 0. Change NUM_MHPM value in cpu_params.svh");
      `endif
      if (MAX_GPR != 32)                                                      $warning("RISC-V compatible designs should set MAX_GPR = 32. See cpu_params.svh");

      if ((Phys_Addr_Lo % 4) != 0)                                            $fatal ("Phys_Addr_Lo must be a multiple of 4. see cpu_params_pkg.sv");
      if ((Phys_Depth % 4) != 0)                                              $fatal ("Phys_Depth must be a multiple of 4. see cpu_params_pkg.sv");

      if ((L1_IC_Lo % 4) != 0)                                                $fatal ("L1_IC_Lo must be a multiple of 4. see cpu_params_pkg.sv");
      if ((Instr_Depth % 4) != 0)                                             $fatal ("Instr_Depth must be a multiple of 4. see cpu_params_pkg.sv");

      if (CL_LEN <  4)                                                        $fatal ("Length of input data to CPU should be 4 bytes or more");
      if (XLEN != 32)                                                         $fatal ("XLEN must be 32 for this RV32 CPU");
      if (CI_SZ != 16)                                                        $fatal ("CI_SZ must be 16 for Compressed Instructions");
      if (ASSEMBLY == SEMANTICS)                                              $fatal ("SEMANTICS value cannot be same as ASSEMBLY");

      if (EV_SEL_SZ > XLEN)                                                   $fatal ("EV_SEL_SZ > XLEN. see cpu_params_pkg.sv");
      if (DEL_SZ > XLEN)                                                      $fatal ("DEL_SZ > XLEN. see cpu_params_pkg.sv");
      
      // Internal I/O address range check
      if (Int_IO_Addr_Hi <= Int_IO_Addr_Lo)                                   $fatal ("Int_IO_Addr_Hi must be > Int_IO_Addr_Lo");

      // External I/O address range check
      if (Ext_IO_Addr_Hi <= Ext_IO_Addr_Lo)                                   $fatal ("Ext_IO_Addr_Hi must be > Ext_IO_Addr_Lo");

      // MSIP_Base_Addr related checks
      if (MSIP_Base_Addr[0])                                                  $fatal ("MSIP_Base_Addr must be 2 byte aligned. i.e. lower bit = 0");
      if (!(MSIP_Base_Addr inside {[Int_IO_Addr_Lo:Int_IO_Addr_Hi]}))         $fatal ("MSIP_Base_Addr must be inside Int_IO_Addr address range");
      if (MSIP_Base_Addr inside {[Ext_IO_Addr_Lo:Ext_IO_Addr_Hi]})            $fatal ("MSIP_Base_Addr must not be inside Ext_IO_Addr address range");
      if (MSIP_Base_Addr inside {[MTIME_Base_Addr:MTIME_Base_Addr+7]})        $fatal ("MSIP_Base_Addr must not be inside MTIME_Base_Addr address range");
      if (MSIP_Base_Addr inside {[MTIMECMP_Base_Addr:MTIMECMP_Base_Addr+7]})  $fatal ("MSIP_Base_Addr must not be inside MTIMECMP_Base_Addr address range");

      // MTIME_Base_Addr related checks
      if (MTIME_Base_Addr[0])                                                 $fatal ("MTIME_Base_Addr must be 2 byte aligned. i.e. lower bit = 0");
      if (!(MTIME_Base_Addr inside {[Int_IO_Addr_Lo:Int_IO_Addr_Hi]}))        $fatal ("MTIME_Base_Addr must be inside Int_IO_Addr address range");
      if (MTIME_Base_Addr inside {[Ext_IO_Addr_Lo:Ext_IO_Addr_Hi]})           $fatal ("MTIME_Base_Addr must not be inside Ext_IO_Addr address range");
      if (MTIME_Base_Addr inside {[MSIP_Base_Addr:MSIP_Base_Addr+3]})         $fatal ("MTIME_Base_Addr must not be inside MSIP_Base_Addr address range");
      if (MTIME_Base_Addr inside {[MTIMECMP_Base_Addr:MTIMECMP_Base_Addr+7]}) $fatal ("MTIME_Base_Addr must not be inside MTIMECMP_Base_Addr address range");

      // MTIMECMP_Base_Addr related checks
      if (MTIMECMP_Base_Addr[0])                                              $fatal ("MTIMECMP_Base_Addr must be 2 byte aligned. i.e. lower bit = 0");
      if (!(MTIMECMP_Base_Addr inside {[Int_IO_Addr_Lo:Int_IO_Addr_Hi]}))     $fatal ("MTIMECMP_Base_Addr must be inside Int_IO_Addr address range");
      if (MTIMECMP_Base_Addr inside {[Ext_IO_Addr_Lo:Ext_IO_Addr_Hi]})        $fatal ("MTIMECMP_Base_Addr must not be inside Ext_IO_Addr address range");
      if (MTIMECMP_Base_Addr inside {[MSIP_Base_Addr:MSIP_Base_Addr+3]})      $fatal ("MTIMECMP_Base_Addr must not be inside MSIP_Base_Addr address range");
      if (MTIMECMP_Base_Addr inside {[MTIME_Base_Addr:MTIME_Base_Addr+7]})    $fatal ("MTIMECMP_Base_Addr must not be inside MTIME_Base_Addr address range");

      // L1 Instruction Cache related checks
      if (L1_IC_Hi <= L1_IC_Lo)                                               $fatal ("L1_IC_Hi must be > L1_IC_Lo");
      if (!(L1_IC_Lo inside {[Phys_Addr_Lo:Phys_Addr_Hi]}))                   $fatal ("L1_IC_Lo must be inside Phys_Addr address range");
      if (!(L1_IC_Hi inside {[Phys_Addr_Lo:Phys_Addr_Hi]}))                   $fatal ("L1_IC_Hi must be inside Phys_Addr address range");
      if (L1_IC_Lo inside {[Int_IO_Addr_Lo:Int_IO_Addr_Hi]})                  $fatal ("L1_IC_Lo must not be inside Int_IO_Addr address range");
      if (L1_IC_Lo inside {[Ext_IO_Addr_Lo:Ext_IO_Addr_Hi]})                  $fatal ("L1_IC_Lo must not be inside Ext_IO_Addr address range");

      // Physical address range check
      if (Phys_Addr_Hi <= Phys_Addr_Lo)                                       $fatal ("Phys_Addr_Hi must be > Phys_Addr_Lo");
      // reset vector related checks
      `ifdef ext_C
      if (RESET_VECTOR_ADDR[0])                                               $fatal ("RESET_VECTOR_ADDR must be 2 byte aligned. i.e. lower bit = 0");
      `else
      if (RESET_VECTOR_ADDR[1:0])                                             $fatal ("RESET_VECTOR_ADDR must be 4 byte aligned. i.e. lower 2 bits = 2'b00");
      `endif
      if (!(RESET_VECTOR_ADDR inside {[Phys_Addr_Lo:Phys_Addr_Hi]}))          $fatal ("RESET_VECTOR_ADDR must be inside Phys_Addr_Lo address range");
      
   endgenerate
