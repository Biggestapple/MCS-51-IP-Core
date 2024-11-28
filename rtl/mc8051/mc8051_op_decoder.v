//----------------------------------------------------------------------------------------------------------
//	FILE: 		mc8051_op_decoder.v
// 	AUTHOR:		Biggest_apple
// 	
//	ABSTRACT:	This is the operation code decoder unit of the cpu
// 	KEYWORDS:	fpga, basic module,signal process
// 
// 	MODIFICATION HISTORY:
//	$Log$
//			Biggest_apple				2024.9.3		Create the file
//			Biggest_apple				2024.9.30		Rebuild All
//-----------------------------------------------------------------------------------------------------------
`timescale 				1ns/1ps
`include				"global_param.v"
module op_decoder(
	input		[7:0]					i_instr_buffer,
	input		[1:0]					i_multi_cycle_times,
	
	output		[`MCODE_WIDTH-1:0]		o_mc_b
);
always @(*)
	casez(i_instr_buffer)
		
	
		default:
			$display ("%m :at time %t Error: Fetched INVALID Instruction in op_decoder_module.", $time);
	endcase

endmodule