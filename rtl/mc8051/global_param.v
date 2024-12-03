//----------------------------------------------------------------------------------------------------------
//	FILE: 		global_param.v
// 	AUTHOR:		Biggest_apple
// 	
//	ABSTRACT:	
// 	KEYWORDS:	fpga, basic module,signal process
// 
// 	MODIFICATION HISTORY:
//	$Log$
//			Biggest_apple				2024.9.3		Create the file
//			Biggest_apple				2024.10.3		Rebuild All
//-----------------------------------------------------------------------------------------------------------
`timescale 				1ns/1ps
//Special Function Register Byte Address
`define					ACC					8'he0
`define					B					8'hF0
`define					SP					8'h81
`define					DPL					8'h82
`define					DPH					8'h83
`define					PSW					8'hd0
//Define the instructions as follows
//Move byte variable instruction group
`define					MOV_A_RN			8'b1110_1zzz
`define					MOV_RN_A			8'b1111_1zzz
`define					MOV_DIR_RN			8'b1000_1zzz
`define					MOV_A_DIR			8'hE5
`define					MOV_A_F_RN			8'b1110_011z
`define					MOV_RN_DIR			8'b1010_1zzz
`define					MOV_RN_IMM			8'b0111_1zzz
`define					MOV_DIR_A			8'hF5
`define					MOV_DIR1_DIR2		8'h85
`define					MOV_DIR_F_RN		8'b1000_011z
`define					MOV_DIR_IMM			8'h75
`define					MOV_F_RN_A			8'b1111_011z
`define					MOV_F_RN_DIR		8'b1010_011z
`define					MOV_F_RN_IMM		8'b0111_011z
//Move bit data instruction group
`define					MOV_C_BIT			8'hA2
`define					MOV_BIT_C			8'h92
`define					MOV_DPTR_IMM		8'h90
// Move Code byte instruction group
`define					MOVC_A_F_DPTRPA		8'h93
`define					MOVC_A_F_PCPA		8'h83
// Move External byte instruction group
`define					MOVX_A_F_RN			8'b1110_001z
`define					MOVX_A_F_DPTR		8'hE0
`define					MOVX_F_RN_A			8'b1111_001z
`define					MOVX_F_DPTR_A		8'hF0
//Special instruction 
`define					DIV_AB				8'h84
`define					MUL_AB				8'hA4
`define					NOP					8'h00
//Stack Operation instruction
`define					POP					8'hD0
`define					PUSH				8'hC0
//subroutine Operation instructio
`define					RET					8'h22
`define					RETI				8'h32
`define					RL_A				8'h23
`define					RLC_A				8'h33
`define					RR_A				8'h03
`define					RRC_A				8'h13
//Set Bit instruction group
`define					SETB_C				8'hD3
`define					SETB_BIT			8'hD2
`define					SJMP				8'h80
`define					SUBB_A_DIR			8'h95
`define					SUBB_A_F_RN			8'b1001_011z
`define					SUBB_A_IMM			8'h94
`define					SUBB_A_RN			8'b1001_1zzz
`define					SWAP_A				8'hC4
//Exchange Accumulator with byte variable
`define					XCH_A_F_RN			8'b1100_011z
`define					XCH_A_DIR			8'hC5
`define					XCH_A_RN			8'b1100_1zzz
`define					XCHD_A_F_RN			8'b1101_011z
//Inc instruction group
`define					INC_A				8'h04
`define					INC_DIR				8'h05
`define					INC_F_RN			8'b0000_011z
`define					INC_RN				8'b0000_1zzz
//Dec instruction group
`define					DEC_A				8'h14
`define					DEC_DIR				8'h15
`define					DEC_F_RN			8'b0001_011z
`define					DEC_RN				8'b0001_1zzz
//Add without Carry instruction group
`define					ADD_A_DIR			8'h25
`define					ADD_A_F_RN			8'b0010_011z
`define					ADD_A_IMM			8'h24
`define					ADD_A_RN			8'b0010_1zzz
//Add with Carry instruction group
`define					ADDC_A_DIR			8'h35
`define					ADDC_A_F_RN			8'b0011_011z
`define					ADDC_A_IMM			8'h34
`define					ADDC_A_RN			8'b0011_1zzz
//Logical-OR for byte variables instruction group
`define					ORL_A_RN			8'b0100_1zzz
`define					ORL_A_DIR			8'h45
`define					ORL_A_F_RN			8'b0100_011z
`define					ORL_A_IMM			8'h44
`define					ORL_DIR_A			8'h42
`define					ORL_DIR_IMM			8'h43
//Logical-AND for byte variables instruction group
`define					ANL_A_DIR			8'h55
`define					ANL_A_F_RN			8'b0101_011z
`define					ANL_A_IMM			8'h54
`define					ANL_A_RN			8'b0101_1zzz
`define					ANL_DIR_A			8'h52
`define					ANL_DIR_IMM			8'h53
//Logical-XR for byte variables instruction group
`define					XRL_A_DIR			8'h65
`define					XRL_A_F_RN			8'b0110_011z
`define					XRL_A_IMM			8'h64
`define					XRL_A_RN			8'b0110_1zzz
`define					XRL_DIR_A			8'h62
`define					XRL_DIR_IMM			8'h63
//Omit ... ...
`define					ORL_C_BIT			8'h72
`define					ORL_C_NBIT			8'hA0
`define					ANL_C_BIT			8'h82
`define					ANL_C_NBIT			8'hB0

`define					ACALL				8'bzzz1_0001
`define					AJMP				8'bzzz0_0001

`define					CJNE_A_DIR			8'hB5
`define					CJNE_A_IMM			8'hB4
`define					CJNE_F_RN			8'b1011_011z
`define					CJNE_RN_IMM			8'b1011_1zzz

`define					CLR_A				8'hE4
`define					CLR_BIT				8'hC2
`define					CLR_C				8'hC3

`define					CPL_A				8'hF4
`define					CPL_BIT				8'hB2
`define					CPL_C				8'hB3

`define					DA_A				8'hD4

`define					DJNZ_RN				8'b1101_1zzz
`define					DJNE_DIR			8'hD5

`define					INC_DPTR			8'hA3
`define					JB					8'h20
`define					JBC					8'h10
`define					JC					8'h40
`define					JMP					8'h73
`define					JNB					8'h30
`define					JNC					8'h50
`define					JNZ					8'h70
`define					JZ					8'h60

`define					LCALL				8'h12
`define					LJMP				8'h02

//Define the cpu phase FSM
`define					S1_0				4'd0
`define					S1_1				4'd1
`define					S2_0				4'd2
`define					S2_1				4'd3
`define					S3_0				4'd4
`define					S3_1				4'd5
`define					S4_0				4'd6
`define					S4_1				4'd7
`define					S5_0				4'd8
`define					S5_1				4'd9,
`define					S6_0				4'd10
`define					S6_1				4'd11

`define					S8_HALT_LOOP		4'd15
//Define the interupt vector table
`define					INT_VECTOR_0		16'h0003
`define					INT_VECTOR_1		16'h000b
`define					INT_VECTOR_2		16'h0013
`define					INT_VECTOR_3		16'h001b
`define					INT_VECTOR_4		16'h0023
`define					INT_VECTOR_5		16'h002b
								//Not used
`define					INT_VECTOR_6		16'h0033
								//Not used
`define					INT_VECTOR_7		16'h003b
								//Not used
								
`define					MCODE_WIDTH			24*2
`define					STACK_RESET			8'h07
								//Basic 8051 Module
`define					IRAM_SIZE			128
`define					IRAM_UPPER_BASE		8'h80
`define					IRAM_LOWER_BASE		8'h00

//Define the fetch mode for S2 & S3
`define					DISCARD_MODE		3'h0
`define					IND_EXROM_MODE		3'h1
`define					IND_EXRAM_MODE		3'h2
`define					IND_IRAM_MODE		3'h3
`define					DIR_IRAM_MODE		3'h4

//Define the write mode for S5
`define					WR_DISCARD_MODE		3'h0
`define					WR_IND_2IRAM_MODE	3'h1
`define					WR_DIR_2IRAM_MODE	3'h1
`define					WR_2EXRAM_MODE		3'h2

`define					PCL_RESET			8'h00
`define					PCH_RESET			8'h00

`define					FROM_NULL_0			3'h0
`define					FROM_S2_BUF			3'h1
`define					FROM_S3_BUF			3'h2
`define					FROM_A_TEMP			3'h3
`define					FROM_B_TEMP			3'h4
`define					FROM_SXRE_0			3'h5
`define					FROM_SXRE_1			3'h6
`define					FROM_S0_MOD			3'h7

`define					TO_IDLE_0			3'h0
`define					TO_ACC_REG			3'h1
`define					TO_BX_REG			3'h2
`define					TO_SP_REG			3'h3
`define					TO_DPTRH_REG		3'h4
`define					TO_DPTRL_REG		3'h5
`define					TO_SX0_REG			3'h6
`define					TO_SX1_REG			3'h7

`define					PSW_RESET			8'h00

`define					NO_FLAG_AFFECT		3'h0
`define					ALL_FLAG_AFFECT		3'h1

//PC reload mode for J_Group instruction
`define					PC_NUL_RELOAD		3'h0
`define					PC_11B_RELOAD		3'h1
`define					PC_ROF_RELOAD		3'h2
`define					PC_IND_RELOAD		3'h3
`define					PC_16B_RELOAD		3'h4
`define					PC_16X_RELOAD		3'h5		
`define					PC_RXF_RELOAD		3'h6
	
//Interrupt Enter Point Address 
`define					INT_VTAB_SADDR		8'h00

//Define the alu op code
`define					ALU_ARI_ADD			5'h00
`define					ALU_ARI_ADDC		5'h01
`define					ALU_ARI_SUBB		5'h02
`define					ALU_ARI_MUL			5'h03
`define					ALU_ARI_DIV			5'h04
`define					ALU_ARI_DA			5'h05
`define					ALU_ARI_RR			5'h06
`define					ALU_ARI_RL			5'h07
`define					ALU_ARI_RRC			5'h08
`define					ALU_ARI_RLC			5'h09
`define					ALU_ARI_AND			5'h0a
`define					ALU_ARI_OR			5'h0b
`define					ALU_ARI_XOR			5'h0c
`define					ALU_ARI_CPL			5'h0d
`define					ALU_ARI_SWAP		5'h0e

//Define the bit operation alu op code
`define					ALU_LOG_ANLC		5'h10
`define					ALU_LOG_ANLNC		5'h11
`define					ALU_LOG_CJNE		5'h12
`define					ALU_LOG_CLB			5'h13
`define					ALU_LOG_CLC			5'h14
`define					ALU_LOG_CPB			5'h15
`define					ALU_LOG_CPC			5'h16
`define					ALU_LOG_MBC			5'h17
`define					ALU_LOG_MCB			5'h18
`define					ALU_LOG_ORC			5'h19
`define					ALU_LOG_ORNC		5'h1a
`define					ALU_LOG_STB			5'h1b
`define					ALU_LOG_STC			5'h1c

`define					ALU_INCDPTR			5'h1d

`define					ALU_IDLE_0			5'h1f

//Conditional compilation for alu
`define					ALU_INCLUDE_MUL		1'b1
`define					ALU_INCLUDE_DIV		1'b1

`define					PSW_M0_RELOAD		3'h0
`define					PSW_M1_RELOAD		3'h1
`define					PSW_M2_RELOAD		3'h2
`define					PSW_M3_RELOAD		3'h3
//Define the JMP active code
`define					JP_IDLE_0			4'h0
`define					JP_NOCOND			4'h1
`define					JP_ACCZER			4'h2
`define					JP_ACCNZE			4'h3

`define					JP_CMODE0			4'h4
`define					JP_CMODE1			4'h5
`define					JP_CMODE2			4'h6

`define					JP_NZMOD0			4'h7
`define					JP_NZMOD1			4'h8

`define					JP_JCMODE			4'h9
`define					JP_JNCMOD			4'ha

`define					JP_JBCMOD			4'hb
`define					JP_JBNCMD			4'hc
//Define the alu_in0_sel
`define					ALU_I0_ACC			3'h0
`define					ALU_I0_S2B			3'h1
`define					ALU_I0_S3B			3'h2
`define					ALU_I0_BX			3'h3
`define					ALU_I0_SP			3'h4
`define					ALU_I0_DPL			3'h5
`define					ALU_I0_SX0			3'h6
`define					ALU_I0_SX1			3'h7
//Define the alu_in1_sel
`define					ALU_IN1_S2B			3'h0
`define					ALU_IN1_S3B			3'h1
`define					ALU_IN1_BX			3'h2
`define					ALU_IN1_P1			3'h3
`define					ALU_IN1_N1			3'h4
`define					ALU_IN1_NU			3'h5
//Define the s2_mem_addr_sel
`define					S2_ADDR_RS			1'b0
`define					S2_ADDR_PC			4'h8
`define					S2_ADDR_INDX16		4'h9
`define					S2_ADDR_INDX8		4'ha
`define					S2_ADDR_DPTR		4'hb
`define					S2_ADDR_DPTRPA		4'hc
`define					S2_ADDR_PCPA		4'hd
`define					S2_ADDR_BITM0		4'he
`define					S2_ADDR_BITM1		4'hf

//Define the s3_mem_addr_sel
`define					S3_ADDR_RS			2'b00
`define					S3_ADDR_INDX8		3'h2
`define					S3_ADDR_BITM1		3'h3
`define					S3_ADDR_SINDX8		3'h4
`define					S3_ADDR_PC			3'h5
`define					S3_ADDR_SX			3'h6
`define					S3_ADDR_SP			3'h7
//Define the s6_mem_addr_sel
`define					S5_ADDR_RS			1'b0
`define					S5_ADDR_INDX8		4'h8
`define					S5_ADDR_SINDX8		4'h9
`define					S5_ADDR_INDX16		4'ha
`define					S5_ADDR_BITM0		4'hb
`define					S5_ADDR_BITM1		4'hc
`define					S5_ADDR_SX			4'hd
`define					S5_ADDR_SP			4'he
//Define the mem_wdata_sel
`define					S5_WR_S2B			4'h0
`define					S5_WR_S3B			4'h1
`define					S5_WR_ACC			4'h2
`define					S5_WR_BX			4'h3
`define					S5_WR_SP			4'h4
`define					S5_WR_SX0			4'h5
`define					S5_WR_SX1			4'h6
`define					S5_WR_PCL			4'h7
`define					S5_WR_PCH			4'h8
`define					S5_WR_SPM0			4'h9
