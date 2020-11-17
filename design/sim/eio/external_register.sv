//
//
//

import cpu_params_pkg::*;
import cpu_structs_pkg::*;
import logic_params_pkg::*;

module external_register (
	input logic          clk_in,     // Clock
	input logic          reset_in,   // synchronous active high reset

	EIO_intf.slave       ext_intf
);
	logic         [31:0] register;
	logic      [RSZ-1:0] reg_wr_data;
	logic 			      reg_wr;



	//find the req cmg in
	typedef enum {WAIT_REQ, RD_ACK, WR_ACK}state;
	state curr_state, next_state;

	always_ff @(posedge clk_in)
	begin
		if (reset_in)
			register    <= '0;
		else if (reg_wr)
			register    <= reg_wr_data;

		if (reset_in)
			curr_state  <= WAIT_REQ;
		else
			curr_state  <= next_state;
	end

   assign ext_intf.ack_fault = FALSE;  // if there are issues, this module can change this logic to assert this signal

	always_comb
	begin
		ext_intf.ack_data = '0;
		ext_intf.ack      = FALSE;
		reg_wr_data       = '0;
		reg_wr            = FALSE;
		next_state        = curr_state;
		case(curr_state)
			WAIT_REQ:begin
						if(ext_intf.req)
						begin
							if (ext_intf.addr == Ext_IO_Addr_Lo)
							begin
								if(ext_intf.wr)
									next_state = WR_ACK;
								else
									next_state = RD_ACK;
							end
						 end
					end
			RD_ACK: begin
						ext_intf.ack      = TRUE;
						ext_intf.ack_data = register;
						next_state        = WAIT_REQ;
					end

			WR_ACK: begin
						ext_intf.ack      = TRUE;
						reg_wr_data       = ext_intf.wr_data;
						reg_wr            = TRUE;
						next_state        = WAIT_REQ;
					end
			default: next_state        = WAIT_REQ; // can you explain why you did this?

		endcase

	end

endmodule

/*
interface EIO_intf;
      logic                      req;                                // I/O Request
      logic          [PC_SZ-1:0] addr;                               // I/O Address
      logic                      rd;                                 // I/O Read signal. 1 = read
      logic                      wr;                                 // I/O Write signal. 1 = write
      logic            [RSZ-1:0] wr_data;                            // I/O Write data that is written when io_wr == 1

      logic                      ack;                                // I/O Acknowledge
      logic            [RSZ-1:0] ack_data;                           // I/O Read data

      modport master(output req, addr, rd, wr, wr_data, input  ack_data, ack, ack_fault);
      modport slave (input  req, addr, rd, wr, wr_data, output ack_data, ack, ack_fault); <------------------------------------------- using this one
endinterface: EIO_intf
*/