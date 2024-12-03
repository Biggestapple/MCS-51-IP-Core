//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
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
//			Biggest_apple				2024.11.29		Again ... :)
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
`timescale 				1ns/1ps
`include				"global_param.v"
module op_decoder(
	input		[7:0]					i_instr_buffer,
	input		[1:0]					i_ci_stage,
	
	output	reg	[`MCODE_WIDTH-1:0]		o_mc_b
);
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
`define                 SIMULATION_VE
/*
`define                 NO_SIMULATION
*/
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
`ifdef SIMULATION_VE
    if(i_ci_stage == 2'b00)
        case(i_instr_buffer)
            `NOP:   o_mc_b  =   

            default:
                begin
                    o_mc_b  =   {`MCODE_WIDTH{1'bz}};
                   $display ("%m :at time %t Warning! In ci_stage %d, fetched invalid op_code %h return 8'bzzzz_zzzz.", $time,	i_ci_stage, i_instr_buffer);
                end
        endcase
    else if(i_ci_stage == 2'b01)
        case(i_instr_buffer)

            default:
                begin
                    o_mc_b  =   {`MCODE_WIDTH{1'bz}};
                   $display ("%m :at time %t Warning! In ci_stage %d, fetched invalid op_code %h return 8'bzzzz_zzzz.", $time,	i_ci_stage, i_instr_buffer);
                end
        endcase
    else if(i_ci_stage == 2'b10)
        case(i_instr_buffer)

            default:
                begin
                    o_mc_b  =   {`MCODE_WIDTH{1'bz}};
                    $display ("%m :at time %t Warning! In ci_stage %d, fetched invalid op_code %h return 8'bzzzz_zzzz.", $time,	i_ci_stage, i_instr_buffer);
                end
        endcase
    else
        case(i_instr_buffer)

            default:
                begin
                    o_mc_b  =   {`MCODE_WIDTH{1'bz}};
                    $display ("%m :at time %t Warning! In ci_stage %d, fetched invalid op_code %h return 8'bzzzz_zzzz.", $time,	i_ci_stage, i_instr_buffer);                end
        endcase
`else
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
    localparam			BASIC_FILENAME	=	"MicroCodeTable.hex";
    reg		[63:0]		mcTable_rom	[0:255*4];
    initial
            $readmemh(BASIC_FILENAME, mcTable_rom, 0,255*4);
    always @(*)
        o_mc_b		=	mcTable_rom[{i_ci_stage,i_instr_buffer}];
`endif
endmodule