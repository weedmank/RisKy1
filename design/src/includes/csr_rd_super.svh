// ----------------------------------------------------------------------------------------------------
// Creative Commons - Attribution - ShareAlike 3.0
// Copyright (c) 2019 Kirk Weedman www.hdlexpress.com
// Notice: For any reuse or distribution, you must make clear to others the license terms of this work.
// see http://creativecommons.org/licenses/by/3.0/
// ----------------------------------------------------------------------------------------------------
// Project       :  RisKy1 - new 5 stage pipelined RISC-V ISA based CPU tailored to the RISC-V RV32IM
// Editor        :  Notepad++
// File          :  csr_rd_super.svh
// Description   :  Contains CSR Read logic for Supervisor mode.  Used in csr_fu.sv
//               :
// Designer      :  Kirk Weedman - kirk@hdlexpress.com
// ----------------------------------------------------------------------------------------------------

   // see riscv-privileged.pdf p. 9
   `ifdef ext_S
      // csr_avail = CSR register exists in this design
      case(csr_addr)
         // ================================================= Supervisor Mode =================================================
         // ------------------------------ Supervisor Trap Setup
         // Supervisor status register.
         // 12'h100 = 12'b0001_0000_0000  sstatus     (read-write)
         12'h100: begin csr_rdata = csr_sstatus;    csr_avail = TRUE; end

         // Supervisor exception delegation register.
         // 12'h102 = 12'b0001_0000_0010  sedeleg     (read-write)
         12'h102: begin csr_rdata = csr_sedeleg;    csr_avail = TRUE; end

         // Supervisor interrupt delegation register.
         // 12'h103 = 12'b0001_0000_0011  sideleg     (read-write)
         12'h103: begin csr_rdata = csr_sideleg;    csr_avail = TRUE; end

         // Supervisor interrupt-enable register.
         // 12'h104 = 12'b0001_0000_0100  sie         (read-write)
         12'h104: begin csr_rdata = csr_sie;        csr_avail = TRUE; end

         // Supervisor trap handler base address.
         // 12'h105 = 12'b0001_0000_0101  stvec       (read-write)
         12'h105: begin csr_rdata = csr_stvec;      csr_avail = TRUE; end

         // Supervisor counter enable.
         // 12'h106 = 12'b0001_0000_0110  scounteren  (read-write)
         12'h106: begin csr_rdata = csr_scounteren; csr_avail = TRUE; end      // see csr_rd_cntr_tmr.svh

         // ------------------------------ Supervisor Trap Handling
         // Scratch register for supervisor trap handlers.
         // 12'h140 = 12'b0001_0100_0000  sscratch    (read-write)
         12'h140: begin csr_rdata = csr_sscratch;   csr_avail = TRUE; end

         // Supervisor exception program counter.
         // 12'h141 = 12'b0001_0100_0001  sepc        (read-write)
         12'h141: begin csr_rdata = csr_sepc;       csr_avail = TRUE; end

         // Supervisor trap cause.
         // 12'h142 = 12'b0001_0100_0010  scause      (read-write)
         12'h142: begin csr_rdata = csr_scause;     csr_avail = TRUE; end

         // Supervisor bad address or instruction.
         // 12'h143 = 12'b0001_0100_0011  stval       (read-write)
         12'h143: begin csr_rdata = csr_stval;      csr_avail = TRUE; end

         // Supervisor interrupt pending.
         // p. 29 SUPERVISOR mode: The logical-OR of the software-writeable bit and the signal from the external interrupt controller is used to generate external
         // interrupts to the supervisor. When the SEIP bit is read with a CSRRW, CSRRS, or CSRRC instruction, the value returned in the rd destination register
         // contains the logical-OR of the software-writable bit and the interrupt signal from the interrupt controller. However, the value used in the  read-modify-write
         // sequence of a CSRRS or CSRRC instruction is only the software-writable SEIP bit, ignoring the interrupt value from the external interrupt controller.
         // 12'h144 = 12'b0001_0100_0100  sip         (read-write)
         12'h144: begin csr_rdata = csr_sip;        csr_avail = TRUE; end

         // ------------------------------ Supervisor Protection and Translation
         // Supervisor address translation and protection.
         // 12'h180 = 12'b0001_1000_0000  satp        (read-write)
         12'h180: begin csr_rdata = csr_satp;       csr_avail = TRUE; end
      endcase
   `endif // ext_S
