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
    input                               i_s1_done_tick,
    input                               i_s2_done_tick,
    input                               i_s3_done_tick,
	
	output	reg	[`MCODE_WIDTH-1:0]      o_mc_b
);
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
`define                 EN_SIMULATION
/*
`define                 NO_SIMULATION
*/
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
`ifdef EN_SIMULATION
    always @(*) begin
        o_mc_b                              =   {`MCODE_WIDTH{1'b0}};
        if(i_ci_stage == 2'b00)
            casez(i_instr_buffer)
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
/*
                DATA TRANSFER
*/
                `NOP            :   o_mc_b  =   {1'b0,`FROM_NULL_0,`TO_IDLE_0,`PC_NUL_RELOAD,`JP_IDLE_0,`PSW_M0_RELOAD,`ALU_I1_S2B,`ALU_I0_ACC,`ALU_IDLE_0,`S5_ADDR_INDX8,`WR_DISCARD_MODE,`S5_WR_S2B,`S3_ADDR_PC,`DISCARD_MODE,1'b0,`S2_ADDR_PC,`DISCARD_MODE,1'b0};
                `MOV_A_IMM      :   o_mc_b  =   {1'b0,`FROM_S2_BUF,`TO_ACC_REG,`PC_NUL_RELOAD,`JP_IDLE_0,`PSW_M0_RELOAD,`ALU_I1_S2B,`ALU_I0_ACC,`ALU_IDLE_0,`S5_ADDR_INDX8,`WR_DISCARD_MODE,`S5_WR_S2B,`S3_ADDR_PC,`DISCARD_MODE,1'b0,`S2_ADDR_PC,`IND_EXROM_MODE,1'b1};
                `MOV_A_RN       :   o_mc_b  =   {1'b0,`FROM_S2_BUF,`TO_ACC_REG,`PC_NUL_RELOAD,`JP_IDLE_0,`PSW_M0_RELOAD,`ALU_I1_S2B,`ALU_I0_ACC,`ALU_IDLE_0,`S5_ADDR_INDX8,`WR_DISCARD_MODE,`S5_WR_S2B,`S3_ADDR_PC,`DISCARD_MODE,1'b0,`S2_ADDR_RS0,`DIR_IRAM_MODE,1'b0};
                `MOV_A_DIR      :   o_mc_b  =   {1'b0,`FROM_S3_BUF,`TO_ACC_REG,`PC_NUL_RELOAD,`JP_IDLE_0,`PSW_M0_RELOAD,`ALU_I1_S2B,`ALU_I0_ACC,`ALU_IDLE_0,`S5_ADDR_INDX8,`WR_DISCARD_MODE,`S5_WR_S2B,`S3_ADDR_INDX8,`DIR_IRAM_MODE,1'b0,`S2_ADDR_PC,`IND_EXROM_MODE,1'b1};
                `MOV_A_F_RN     :   o_mc_b  =   {1'b0,`FROM_S3_BUF,`TO_ACC_REG,`PC_NUL_RELOAD,`JP_IDLE_0,`PSW_M0_RELOAD,`ALU_I1_S2B,`ALU_I0_ACC,`ALU_IDLE_0,`S5_ADDR_INDX8,`WR_DISCARD_MODE,`S5_WR_S2B,`S3_ADDR_INDX8,`IND_IRAM_MODE,1'b0,`S2_ADDR_RS1,`DIR_IRAM_MODE,1'b0};
                `MOV_RN_A       :   o_mc_b  =   {1'b0,`FROM_NULL_0,`TO_IDLE_0,`PC_NUL_RELOAD,`JP_IDLE_0,`PSW_M0_RELOAD,`ALU_I1_S2B,`ALU_I0_ACC,`ALU_IDLE_0,`S5_ADDR_RS0,`WR_DIR_2IRAM_MODE,`S5_WR_ACC,`S3_ADDR_PC,`DISCARD_MODE,1'b0,`S2_ADDR_PC,`DISCARD_MODE,1'b0};
                `MOV_RN_DIR     :   o_mc_b  =   {1'b0,`FROM_NULL_0,`TO_IDLE_0,`PC_NUL_RELOAD,`JP_IDLE_0,`PSW_M0_RELOAD,`ALU_I1_S2B,`ALU_I0_ACC,`ALU_IDLE_0,`S5_ADDR_RS0,`WR_DIR_2IRAM_MODE,`S5_WR_S3B,`S3_ADDR_INDX8,`DIR_IRAM_MODE,1'b0,`S2_ADDR_PC,`IND_EXROM_MODE,1'b1};
                `MOV_RN_IMM     :   o_mc_b  =   {1'b0,`FROM_NULL_0,`TO_IDLE_0,`PC_NUL_RELOAD,`JP_IDLE_0,`PSW_M0_RELOAD,`ALU_I1_S2B,`ALU_I0_ACC,`ALU_IDLE_0,`S5_ADDR_RS0,`WR_DIR_2IRAM_MODE,`S5_WR_S2B,`S3_ADDR_PC,`DISCARD_MODE,1'b0,`S2_ADDR_PC,`IND_EXROM_MODE,1'b1};
                `MOV_DIR_A      :   o_mc_b  =   {1'b0,`FROM_NULL_0,`TO_IDLE_0,`PC_NUL_RELOAD,`JP_IDLE_0,`PSW_M0_RELOAD,`ALU_I1_S2B,`ALU_I0_ACC,`ALU_IDLE_0,`S5_ADDR_INDX8,`WR_DIR_2IRAM_MODE,`S5_WR_ACC,`S3_ADDR_PC,`DISCARD_MODE,1'b0,`S2_ADDR_PC,`IND_EXROM_MODE,1'b1};
                `MOV_DIR_RN     :   o_mc_b  =   {1'b1,`FROM_S2_BUF,`TO_SX0_REG,`PC_NUL_RELOAD,`JP_IDLE_0,`PSW_M0_RELOAD,`ALU_I1_S2B,`ALU_I0_ACC,`ALU_IDLE_0,`S5_ADDR_INDX8,`WR_DISCARD_MODE,`S5_WR_S2B,`S3_ADDR_PC,`IND_EXROM_MODE,1'b1,`S2_ADDR_RS0,`DIR_IRAM_MODE,1'b0};
                `MOV_DIR1_DIR2  :   o_mc_b  =   {1'b1,`FROM_S3_BUF,`TO_SX0_REG,`PC_NUL_RELOAD,`JP_IDLE_0,`PSW_M0_RELOAD,`ALU_I1_S2B,`ALU_I0_ACC,`ALU_IDLE_0,`S5_ADDR_INDX8,`WR_DISCARD_MODE,`S5_WR_S2B,`S3_ADDR_INDX8,`DIR_IRAM_MODE,1'b0,`S2_ADDR_PC,`IND_EXROM_MODE,1'b1};
//TODO: UNTESTED    
                `MOV_DIR_F_RN   :   o_mc_b  =   {1'b1,`FROM_NULL_0,`TO_IDLE_0,`PC_NUL_RELOAD,`JP_IDLE_0,`PSW_M0_RELOAD,`ALU_I1_S2B,`ALU_I0_ACC,`ALU_IDLE_0,`S5_ADDR_INDX8,`WR_DISCARD_MODE,`S5_WR_S2B,`S3_ADDR_PC,`IND_EXROM_MODE,1'b1,`S2_ADDR_RS1,`IND_IRAM_MODE,1'b0};

                `MOV_DIR_IMM    :   o_mc_b  =   {1'b0,`FROM_NULL_0,`TO_IDLE_0,`PC_NUL_RELOAD,`JP_IDLE_0,`PSW_M0_RELOAD,`ALU_I1_S2B,`ALU_I0_ACC,`ALU_IDLE_0,`S5_ADDR_INDX8,`WR_DIR_2IRAM_MODE,`S5_WR_S3B,`S3_ADDR_PC,`IND_EXROM_MODE,1'b1,`S2_ADDR_PC,`IND_EXROM_MODE,1'b1};
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
/* 
                ARITHMETIC OPERATION
*/
                `ADD_A_IMM      :   o_mc_b  =   {1'b0,`FROM_A_TEMP,`TO_ACC_REG,`PC_NUL_RELOAD,`JP_IDLE_0,`PSW_M1_RELOAD,`ALU_I1_S2B,`ALU_I0_ACC,`ALU_ARI_ADD,`S5_ADDR_INDX8,`WR_DISCARD_MODE,`S5_WR_S2B,`S3_ADDR_PC,`DISCARD_MODE,1'b0,`S2_ADDR_PC,`IND_EXROM_MODE,1'b1};
                `ADDC_A_IMM     :   o_mc_b  =   {1'b0,`FROM_A_TEMP,`TO_ACC_REG,`PC_NUL_RELOAD,`JP_IDLE_0,`PSW_M1_RELOAD,`ALU_I1_S2B,`ALU_I0_ACC,`ALU_ARI_ADDC,`S5_ADDR_INDX8,`WR_DISCARD_MODE,`S5_WR_S2B,`S3_ADDR_PC,`DISCARD_MODE,1'b0,`S2_ADDR_PC,`IND_EXROM_MODE,1'b1};
                `DEC_A          :   o_mc_b  =   {1'b0,`FROM_A_TEMP,`TO_ACC_REG,`PC_NUL_RELOAD,`JP_IDLE_0,`PSW_M1_RELOAD,`ALU_I1_N1,`ALU_I0_ACC,`ALU_ARI_ADD,`S5_ADDR_INDX8,`WR_DISCARD_MODE,`S5_WR_S2B,`S3_ADDR_PC,`DISCARD_MODE,1'b0,`S2_ADDR_PC,`DISCARD_MODE,1'b0};
                
                `MUL_AB         :   o_mc_b  =   {1'b1,`FROM_A_TEMP,`TO_ACC_REG,`PC_NUL_RELOAD,`JP_IDLE_0,`PSW_M1_RELOAD,`ALU_I1_BX,`ALU_I0_ACC,`ALU_ARI_MUL,`S5_ADDR_INDX8,`WR_DISCARD_MODE,`S5_WR_S2B,`S3_ADDR_PC,`DISCARD_MODE,1'b0,`S2_ADDR_PC,`DISCARD_MODE,1'b0};
                `DIV_AB         :   o_mc_b  =   {1'b1,`FROM_A_TEMP,`TO_ACC_REG,`PC_NUL_RELOAD,`JP_IDLE_0,`PSW_M1_RELOAD,`ALU_I1_BX,`ALU_I0_ACC,`ALU_ARI_DIV,`S5_ADDR_INDX8,`WR_DISCARD_MODE,`S5_WR_S2B,`S3_ADDR_PC,`DISCARD_MODE,1'b0,`S2_ADDR_PC,`DISCARD_MODE,1'b0};
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
/*
                PROGRAM BRANCHING
*/
                `JZ             :   o_mc_b  =   {1'b0,`FROM_NULL_0,`TO_IDLE_0,`PC_ROF_RELOAD,`JP_ACCZER,`PSW_M0_RELOAD,`ALU_I1_S2B,`ALU_I0_ACC,`ALU_IDLE_0,`S5_ADDR_INDX8,`WR_DISCARD_MODE,`S5_WR_S2B,`S3_ADDR_PC,`DISCARD_MODE,1'b0,`S2_ADDR_PC,`IND_EXROM_MODE,1'b1};
                `JNZ            :   o_mc_b  =   {1'b0,`FROM_NULL_0,`TO_IDLE_0,`PC_ROF_RELOAD,`JP_ACCNZE,`PSW_M0_RELOAD,`ALU_I1_S2B,`ALU_I0_ACC,`ALU_IDLE_0,`S5_ADDR_INDX8,`WR_DISCARD_MODE,`S5_WR_S2B,`S3_ADDR_PC,`DISCARD_MODE,1'b0,`S2_ADDR_PC,`IND_EXROM_MODE,1'b1};
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
                default:
                    begin
                        o_mc_b  =   {`MCODE_WIDTH{1'bz}};
                        if(i_s1_done_tick |i_s2_done_tick|i_s3_done_tick)
                            $display ("%m :at time %t Warning! In ci_stage %d, fetched invalid op_code %h return 8'bzzzz_zzzz.", $time,	i_ci_stage, i_instr_buffer);
                    end
            endcase
        else if(i_ci_stage == 2'b01)
            casez(i_instr_buffer)
                `MOV_DIR_RN     :   o_mc_b  =   {1'b0,`FROM_NULL_0,`TO_IDLE_0,`PC_NUL_RELOAD,`JP_IDLE_0,`PSW_M0_RELOAD,`ALU_I1_S2B,`ALU_I0_ACC,`ALU_IDLE_0,`S5_ADDR_SINDX8,`WR_DIR_2IRAM_MODE,`S5_WR_SX0,`S3_ADDR_PC,`DISCARD_MODE,1'b0,`S2_ADDR_PC,`DISCARD_MODE,1'b0};
                `MOV_DIR1_DIR2  :   o_mc_b  =   {1'b0,`FROM_NULL_0,`TO_IDLE_0,`PC_NUL_RELOAD,`JP_IDLE_0,`PSW_M0_RELOAD,`ALU_I1_S2B,`ALU_I0_ACC,`ALU_IDLE_0,`S5_ADDR_INDX8,`WR_DIR_2IRAM_MODE,`S5_WR_SX0,`S3_ADDR_PC,`DISCARD_MODE,1'b0,`S2_ADDR_PC,`IND_EXROM_MODE,1'b1};
                `MOV_DIR_F_RN   :   o_mc_b  =   {1'b0,`FROM_NULL_0,`TO_IDLE_0,`PC_NUL_RELOAD,`JP_IDLE_0,`PSW_M0_RELOAD,`ALU_I1_S2B,`ALU_I0_ACC,`ALU_IDLE_0,`S5_ADDR_SINDX8,`WR_DIR_2IRAM_MODE,`S5_WR_S2B,`S3_ADDR_PC,`DISCARD_MODE,1'b0,`S2_ADDR_INDX8,`IND_IRAM_MODE,1'b0};

                `MUL_AB         :   o_mc_b  =   {1'b0,`FROM_B_TEMP,`TO_BX_REG,`PC_NUL_RELOAD,`JP_IDLE_0,`PSW_M0_RELOAD,`ALU_I1_S2B,`ALU_I0_ACC,`ALU_IDLE_0,`S5_ADDR_INDX8,`WR_DISCARD_MODE,`S5_WR_S2B,`S3_ADDR_PC,`DISCARD_MODE,1'b0,`S2_ADDR_PC,`DISCARD_MODE,1'b0};   
                `DIV_AB         :   o_mc_b  =   {1'b0,`FROM_B_TEMP,`TO_BX_REG,`PC_NUL_RELOAD,`JP_IDLE_0,`PSW_M0_RELOAD,`ALU_I1_S2B,`ALU_I0_ACC,`ALU_IDLE_0,`S5_ADDR_INDX8,`WR_DISCARD_MODE,`S5_WR_S2B,`S3_ADDR_PC,`DISCARD_MODE,1'b0,`S2_ADDR_PC,`DISCARD_MODE,1'b0};   
                default:
                    begin
                        o_mc_b  =   {`MCODE_WIDTH{1'bz}};
                        if(i_s1_done_tick |i_s2_done_tick|i_s3_done_tick)
                            $display ("%m :at time %t Warning! In ci_stage %d, fetched invalid op_code %h return 8'bzzzz_zzzz.", $time,	i_ci_stage, i_instr_buffer);
                    end
            endcase
        else if(i_ci_stage == 2'b10)
            casez(i_instr_buffer)

                default:
                    begin
                        o_mc_b  =   {`MCODE_WIDTH{1'bz}};
                        if(i_s1_done_tick |i_s2_done_tick|i_s3_done_tick)
                            $display ("%m :at time %t Warning! In ci_stage %d, fetched invalid op_code %h return 8'bzzzz_zzzz.", $time,	i_ci_stage, i_instr_buffer);
                    end
            endcase
        else
            casez(i_instr_buffer)

                default:
                    begin
                        o_mc_b  =   {`MCODE_WIDTH{1'bz}};
                        if(i_s1_done_tick |i_s2_done_tick|i_s3_done_tick)
                            $display ("%m :at time %t Warning! In ci_stage %d, fetched invalid op_code %h return 8'bzzzz_zzzz.", $time,	i_ci_stage, i_instr_buffer);                
                    end
            endcase
    end
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