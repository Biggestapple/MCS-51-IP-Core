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
//-----------------------------------------------------------------------------------------------------------
`timescale 				1ns/1ps
//Define the instructions
parameter	[4:0]		MOV_A_RN	=	5'b1110_1,	MOV_RN_A	=	5'b1111_1,				MOV_DIR_RN	=5'b1000_1,
						XCH_A_RN	=	5'b1100_1,	ADD_A_RN	=	5'b0010_1,				ADDC_A_RN	=5'b0011_1,
						SUBB_A_RN	=	5'b1001_1,	INC_RN		=	5'b0000_1,				DEC_RN		=5'b0001_1,
						ANL_A_RN	=	5'b0101_1,	ORL_A_RN	=	5'b0100_1,				XRL_A_RN	=5'b0110_1,	
						CJNE_RN_IMM	=	5'b1011_1,	DJNZ_RN		=	5'b1101_1,				MOV_RN_DIR	=5'b1010_1,
						MOV_RN_IMM	=	5'b0111_1
						;
parameter	[7:0]		INTERRUPT_P0=	8'hFA;
parameter	[4:0]		ACALL		=	5'b10001,	AJMP		=	5'b00001;					
parameter	[7:0]		MOV_A_DIR	=	8'hE5,MOV_A_F_R0 	=8'hE6,	MOV_A_F_R1 	=8'hE7,		MOV_A_IMM	 	=8'h74,
						MOV_DIR_A 	=8'hF5,		MOV_DIR1_DIR2=8'h85,
						MOV_DIR_F_R0=	8'h86,MOV_DIR_F_R1	=8'h87,	MOV_DIR_IMM	=8'h75,		MOV_F_R0_A 	=8'hF6,
						MOV_F_R1_A	=	8'hF7,MOV_F_R0_DIR	=8'hA6,	MOV_F_R1_DIR=8'hA7,		MOV_F_R0_IMM=8'h76,
						MOV_F_R1_IMM=	8'h77,MOV_DPTR_IMM	=8'h90,	MOVC_A_F_DPTRPA	=8'h93,	MOVC_A_F_PCPA=8'h83,
						MOVX_A_F_R0	=8'hE2,MOVX_A_F_R1		=8'hE3,	MOVX_A_F_DPTR	=8'hE0,	MOVX_F_R0_A	=8'hF2,	
						MOVX_F_R1_A	=8'hF3,MOVX_F_DPTR_A	=8'hF0,	PUSH		=8'hC0,		POP			=8'hD0,
						XCH_A_DIR	=8'hC5,XCH_A_F_R0		=8'hC6,	XCH_A_F_R1	=8'hC7,		XCHD_A_F_R0	=8'hD6,
						XCHD_A_F_R1	=8'hD7,SWAP_A			=8'hC4,
						
						
						ADD_A_DIR	=8'h25,ADD_A_F_R0		=8'h26,	ADD_A_F_R1	=8'h27,		ADD_A_IMM	=8'h24,
						ADDC_A_DIR	=8'h35,ADDC_A_F_R0		=8'h36,	ADDC_A_F_R1	=8'h37,		ADDC_A_IMM	=8'h34,
						SUBB_A_DIR	=8'h95,SUBB_A_F_R0		=8'h96,	SUBB_A_F_R1	=8'h97,		SUBB_A_IMM	=8'h94,
						INC_A		=8'h04,INC_DIR			=8'h05,	INC_F_R0	=8'h06,		INC_F_R1	=8'h07,
						DEC_A		=8'h14,DEC_DIR			=8'h15,	DEC_F_R0	=8'h16,		DEC_F_R1	=8'h17,
						INC_DPTR	=8'hA3,MUL_AB			=8'hA4,	DIV_AB		=8'h84,		DA_A		=8'hD4,
						
						ANL_A_DIR	=8'h55,ANL_A_F_R0		=8'h56,	ANL_A_F_R1	=8'h57,		ANL_A_IMM	=8'h54,
						ANL_DIR_A	=8'h52,ANL_DIR_IMM		=8'h53,	
						ORL_A_DIR	=8'h45,ORL_A_F_R0		=8'h46,	ORL_A_F_R1	=8'h47,		ORL_A_IMM	=8'h44,
						ORL_DIR_A	=8'h42,ORL_DIR_IMM		=8'h43,	
						XRL_A_DIR	=8'h65,XRL_A_F_R0		=8'h66,	XRL_A_F_R1	=8'h67,		XRL_A_IMM	=8'h64,
						XRL_DIR_A	=8'h62,XRL_DIR_IMM		=8'h63,	
						CLR_A		=8'hE4,CPL_A			=8'hF4,	RL_A		=8'h23,		RLC_A		=8'h33,
						RR_A		=8'h03,RRC_A			=8'h13,
						
						LCALL		=8'h12,RET				=8'h22,	RETI		=8'h32,		LJMP		=8'h02,
						SJMP		=8'h80,JMP				=8'h73,	JZ			=8'h60,		JNZ			=8'h70,
						CJNE_A_DIR	=8'hB5,CJNE_A_IMM		=8'hB4,	CJNE_F_R0	=8'hB6,		CJNE_F_R1	=8'hB7,
						NOP			=8'h00,
						
						CLR_C		=8'hC3,CLR_BIT			=8'hC2,	SETB_C		=8'hD3,		SETB_BIT	=8'hD2,
						CPL_C		=8'hB3,CPL_BIT			=8'hB2,	ANL_C_BIT	=8'h82,		ANL_C_NBIT	=8'hB0,
						ORL_C_BIT	=8'h72,ORL_C_NBIT		=8'hA0,	MOV_C_BIT	=8'hA2,		MOV_BIT_C	=8'h92,
						
						JC			=8'h40,JNC				=8'h50,	JB			=8'h20,		JNB			=8'h30,
						JBC			=8'h10
						;


//Define the alu op code
parameter	[3:0]		ALU_SUM			=	4'h0,
						ALU_ANDS		=	4'h1,
						ALU_XOR			=	4'h2,
						ALU_OR			=	4'h3,
						ALU_RL			=	4'h4,
						ALU_CPL			=	4'h5,
						ALU_RR			=	4'h6,
						ALU_SWAP		=	4'h7,
						ALU_SUMC		=	4'h8,
						ALU_SUB			=	4'h9,
						ALU_RLC			=	4'ha,
						ALU_RRC			=	4'hb;
//Define the cpu phase FSM
parameter				S1_0			=	4'd0,
						S1_1			=	4'd1,
						S2_0			=	4'd2,
						S2_1			=	4'd3,
						S3_0			=	4'd4,
						S3_1			=	4'd5,
						S4_0			=	4'd6,
						S4_1			=	4'd7,
						S5_0			=	4'd8,
						S5_1			=	4'd9,
						S6_0			=	4'd10,
						S6_1			=	4'd11,
						S7_0			=	4'd12,
						S7_1			=	4'd13,
						S8_0			=	4'd14,
						S8_1			=	4'd15;
//Define the interupt vector table

parameter				INT_VECTOR_0	=	16'h0003,
						INT_VECTOR_1	=	16'h000b,
						INT_VECTOR_2	=	16'h0013,
						INT_VECTOR_3	=	16'h001b,
						INT_VECTOR_4	=	16'h0023,
						INT_VECTOR_5	=	16'h002b,
								//Not used
						INT_VECTOR_6	=	16'h0033,
								//Not used
						INT_VECTOR_7	=	16'h003b;	
								//Not used
//Special Function Register Byte Address
`define					ACC					8'he0
`define					B					8'hF0
`define					SP					8'h81
`define					DPL					8'h82
`define					DPH					8'h83
`define					PSW					8'hd0

