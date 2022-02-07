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
// File          :  csr_checks.svh
// Description   :  use in RisKy1_core.sv to check CSR configuration parameters
//               :
// Designer      :  Kirk Weedman - kirk@hdlexpress.com
// ----------------------------------------------------------------------------------------------------
   generate
      if (MAX_CSR != 4096)                                                    $fatal ("MAX_CSR must be 4096");

      if (MISA[0])                                                            $fatal ("MISA[0] set! This CPU does not yet support Atominc Instructions");
      if (MISA[1])                                                            $fatal ("MISA[1] set! This CPU does not yet support Bit Manipulation Instructions");
      if (MISA[3])                                                            $fatal ("MISA[3] set! This CPU does not yet support Double Precision Instructions");
      if (MISA[4])                                                            $fatal ("MISA[4] set! This CPU does not yet support RV32E base ISA");
      if (MISA[5])                                                            $fatal ("MISA[5] set! This CPU does not yet support Single Precision Floating-Point");
      if (MISA[6])                                                            $fatal ("MISA[6] set! This is a reserved bit");
      if (MISA[7])                                                            $fatal ("MISA[7] set! This CPU does not yet support Hypervisor extension");
      if (!MISA[8])                                                           $fatal ("MISA[8] cleared! This CPU is RV32i and this bit MUST be set");
      if (MISA[9])                                                            $fatal ("MISA[9] set! This CPU does not yet support Dynamically Translated Language extension");
      if (MISA[10])                                                           $fatal ("MISA[10] set! This is a reserved bit");
      if (MISA[11])                                                           $fatal ("MISA[11] set! This CPU does not yet support Decimal FLoating-Point extension");
      if (MISA[14])                                                           $fatal ("MISA[14] set! This is a reserved bit");
      if (MISA[15])                                                           $fatal ("MISA[15] set! This CPU does not yet support Packed-SIMD extension");
      if (MISA[16])                                                           $fatal ("MISA[16] set! This CPU does not yet support Quad-Precision Floating Point extension");
      if (MISA[17])                                                           $fatal ("MISA[17] set! This is a reserved bit");
      if (MISA[19])                                                           $fatal ("MISA[19] set! This CPU does not yet support Transactional Memory extension");
      if (MISA[21])                                                           $fatal ("MISA[19] set! This CPU does not yet support Vector extension");
      if (MISA[22])                                                           $fatal ("MISA[22] set! This is a reserved bit");
      if (MISA[23])                                                           $fatal ("MISA[23] set! This CPU does not yet support Non-Standard extension");
      if (MISA[24])                                                           $fatal ("MISA[24] set! This is a reserved bit");
      if (MISA[25])                                                           $fatal ("MISA[25] set! This is a reserved bit");
      if (MISA[29:26])                                                        $fatal ("MISA[29:26] These bits should remain at 0");
      if (MISA[31:30] != 1)                                                   $fatal ("MXL = %0d. This CPU only allows MXL of 1 (i.e. 32 bit design)", MISA[31:30]);
      if (MISA[8] & MISA[4])                                                  $fatal ("Both MISA[4] and MISA[8] bits set.  Can ony be RV32E or RV32I, but not both");
      if (MISA[3] & !MISA[5])                                                 $fatal ("MISA[3] set and MISA[5] cleared.  If D is set, then F must also be set");

      if (MISA_RO != 32'hFFFF_FFFF)                                           $warning ("Currently, no logic is implemented to allow dynamic change of this register mask");

//      if (SET_MCOUNTINHIBIT == 1)                                             $warning("Setting SET_MCOUNTINHIBIT == 1 forces CSR to read a constant value of SET_MCOUNTINHIBIT_BITS. See csr_params.svh");
//      if (SET_MCOUNTINHIBIT >= 2)                                             $fatal ("SET_MCOUNTINHIBIT must be 0 or 1");
//      if (SET_MCOUNTINHIBIT_BITS < (1<<32))                                   $error ("SET_MCOUNTINHIBIT_BITS should only be 32 bits in width");
      if (NUM_MHPM > 29)                                                      $fatal ("NUM_MHPM must be a value of 29 or less");


      if (MTVEC_INIT & 2)                                                     $warning("MTVEC_INIT[1] is set.  Mode values >= 2 are Reserved. This bit will be set to 0");
      `ifdef ext_S
      if (STVEC_INIT & 2)                                                     $warning("STVEC_INIT[1] is set.  Mode values >= 2 are Reserved. This bit will be set to 0");
      `endif
      `ifdef ext_U
      if (UTVEC_INIT & 2)                                                     $fatal("UTVEC_INIT[1] is set.  Mode values >= 2 are Reserved. Fix UTVEC_INIT[1]");
      `endif


      if (MEDLG_INIT[11] != FALSE)                                            $fatal ("medeleg[11] should be hardwired to 0. See p 29 riscv-privileged.pdf");
      if (SEDLG_INIT[11:9] != 3'b0)                                           $fatal ("sedeleg[11:9] should be hardwired to 0. See p 29 riscv-privileged.pdf");
      if (MEDLG_INIT & MEDLG_RO)                                              $fatal ("An implementation shall not hardwire any delegation bits to one.\n See parameters MEDLG_INIT and MEDLG_MASK are in cpu_params_pkg.sv");
      if (MIDLG_INIT & MIDLG_RO)                                              $fatal ("An implementation shall not hardwire any delegation bits to one.\n See parameters MIDLG_INIT and MIDLG_MASK are in cpu_params_pkg.sv");
      if (SEDLG_INIT & SEDLG_RO)                                              $fatal ("An implementation shall not hardwire any delegation bits to one.\n See parameters SEDLG_INIT and SEDLG_MASK are in cpu_params_pkg.sv");
      if (SIDLG_INIT & SIDLG_RO)                                              $fatal ("An implementation shall not hardwire any delegation bits to one.\n See parameters SIDLG_INIT and SIDLG_MASK are in cpu_params_pkg.sv");
   endgenerate

