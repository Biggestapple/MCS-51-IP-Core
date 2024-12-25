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
//-----------------------------------------------------------------------------------------------------------
`timescale 				1ns/1ps
`include				"global_param.v"
module	mc_decoder(
	input		[7:0]		i_instr_buf,
	input		[1:0]		i_multi_cycle_times,
	
	output		[43:0]		o_mc_b
);
							/*
The content of o_mc_b:
	BITS	|					FUNCTION	|
	0							Whether fetch data or instruction in S2 phase or not (if not the phase will turn to S4_0 automatically)
	1							Whether fetch data or instruction in S3 phase or not (if not the phase will turn to S4_0 automatically)
	2							If fetch data from S2, this bit will decide where the data comes from ROM or RAM,if fetch the data from ROM the PC value will add one automatically
								Note:Default from PRG --> 0 ;RAM --> 1;
	[6:3]						This is called the S2 memory address sel which decides where the address comes from 
	7							If fetch data from S3, this bit will decide where the data comes from ROM or RAM,if fetch the data from ROM the PC value will add one automatically
	[10:8]						This is called the S3 memory address sel which decides where the address comes from 
	11							This bit -indicates whether the instruction needs multi-cycles
	[14:12]						Target register sel bits that decides which register such as ax,bx and etc will be written new byte in S4 and S5
	[17:15]						These bits decide where the byte comes from .."reg_w_mux_ss"
	[21:18]						These bits decide where the mem_wdata's address comes from "s6_mem_addr_sel"
	[25:22]						These bits decide where the mem_wdata comes from	"mem_wdata_mux_sel"
	26							This bit shows if the statue register would be updated in s4_1 phase "bit_oper_flag"
	27							This bit is used for sub related instruction "ax_comp_o"
	
	(alu_mode)					---//	bit_oper_flag	==	1'b0 && is_jump_flag	==1'b0
	
	[31:28]						These bits decide the operation of the alu "alu_mode_sel"
	
	[33:32]						"[is_base_pch,is_base_pcl]" for PC+A ..
	[36:34]						These bits select where the alu's in0 data comes from "alu_in_0_mux_sel"
	[40:37]						These bits select where the alu's in1 data comes from "alu_in_1_mux_sel"
	
	(bit mode)					---//	bit_oper_flag	==	1'b1 && is_jump_flag	==1'b0
	
	[31:28]						These bits decide which register to carry bit operation		"bit_sel"
	34							This bit clears or sets the specific bit		"set_or_clr"								
	[40:37]						These bits decide which bit operation to carry	on "bit_mode_sel"
	
	[42:41]						[is_jump_flag,is_call]	for sub-routine and interrupt service
	
	(jp mode)					--//	bit_oper_flag	(don't care) && is_jump_flag	==1'b1
	[29:28]						"pcl_w_sel"
	[31:30]						"pch_w_sel"
	[33:32]						"pc_jgen_sel"
	[42:34]						Reserved
	
	43							This bit will decide whether write data to ram
							*/
always @(*)
if(i_multi_cycle_times == 2'b00)
	casez(i_instr_buf)
		{MOV_A_RN,3'bz}:
			o_mc_b	=	{1'b0,2'b00,4'h0,3'b000,2'b00,4'h0,1'b0,1'b0,4'h0,4'h0,3'b000,3'd0,1'b0,3'b000,1'b0,{1'b0,i_instr_buf[2:0]},1'b1,1'b0,1'b1};
		MOV_A_DIR:
			o_mc_b	=	{1'b0,2'b00,4'h0,3'b000,2'b00,4'h0,1'b0,1'b0,4'h0,4'h0,3'b001,3'd0,	1'b0,3'b000,1'b1,4'h8,1'b0,1'b1,1'b1};
			
		MOV_A_F_R0:
			o_mc_b	=	{1'b0,2'b00,4'h0,3'b000,2'b00,4'h0,1'b0,1'b0,4'h0,4'h0,3'b001,3'd0,	1'b0,3'b000,1'b1,4'h0,1'b1,1'b1,1'b1};
		MOV_A_F_R1:
			o_mc_b	=	{1'b0,2'b00,4'h0,3'b000,2'b00,4'h0,1'b0,1'b0,4'h0,4'h0,3'b001,3'd0,	1'b0,3'b000,1'b1,4'h1,1'b1,1'b1,1'b1};
		
		{MOV_RN_A,3'bz}:
			o_mc_b	=	{1'b1,2'b00,4'h0,3'b000,2'b00,4'h0,1'b0,1'b0,4'h0,{1'b0,i_instr_buf[2:0]},3'b100,3'd0,1'b0,3'b000,1'b0,4'h0,1'b0,1'b0,1'b0};
		MOV_A_IMM:
			o_mc_b	=	{1'b0,2'b00,4'h0,3'b000,2'b00,4'h0,1'b0,1'b0,4'h0,4'h0,3'b000,3'd0,	1'b0,3'b000,1'b0,4'h8,1'b0,1'b0,1'b1};
		{MOV_DIR_RN,3'bz}:
			o_mc_b	=	{1'b1,2'b00,4'h0,3'b000,2'b00,4'h0,1'b0,1'b0,4'h1,4'h9,3'b100,3'd0,	1'b0,3'b111,1'b0,{1'b0,i_instr_buf[2:0]},1'b1,1'b1,1'b1};
		{MOV_RN_DIR,3'bz}:
			o_mc_b	=	{1'b1,2'b00,4'h0,3'b000,2'b00,4'h0,1'b0,1'b0,4'h2,{1'b0,i_instr_buf[2:0]},3'b100,3'd0,	1'b0,3'b000,1'b1,4'h8,1'b0,1'b1,1'b1};
		{MOV_RN_IMM,3'bz}:
			o_mc_b	=	{1'b1,2'b00,4'h0,3'b000,2'b00,4'h0,1'b0,1'b0,4'h1,{1'b0,i_instr_buf[2:0]},3'b100,3'd0,	1'b0,3'b000,1'b0,4'h8,1'b0,1'b0,1'b1};
		MOV_DIR_A:
			o_mc_b	=	{1'b1,2'b00,4'h0,3'b000,2'b00,4'h0,1'b0,1'b0,4'h0,4'h8,3'b100,3'd0,	1'b0,3'b000,1'b0,4'h8,1'b0,1'b0,1'b1};
		MOV_DIR1_DIR2:
			o_mc_b	=	{1'b0,2'b00,4'h0,3'b000,2'b00,4'h0,1'b0,1'b0,4'h0,4'h0,3'b100,3'd0,	1'b1,3'b111,1'b0,4'h8,1'b0,1'b1,1'b1};
		MOV_DIR_F_R0:
			o_mc_b	=	{1'b0,2'b00,4'h0,3'b000,2'b00,4'h0,1'b0,1'b0,4'h0,4'h0,3'b100,3'd0,	1'b1,3'b111,1'b0,4'h0,1'b1,1'b1,1'b1};
		MOV_DIR_F_R1:
			o_mc_b	=	{1'b0,2'b00,4'h0,3'b000,2'b00,4'h0,1'b0,1'b0,4'h0,4'h0,3'b100,3'd0,	1'b1,3'b111,1'b0,4'h1,1'b1,1'b1,1'b1};
		MOV_DIR_IMM:
			o_mc_b	=	{1'b1,2'b00,4'h0,3'b000,2'b00,4'h0,1'b0,1'b0,4'h2,4'h8,3'b100,3'd0,	1'b0,3'b111,1'b0,4'h8,1'b0,1'b1,1'b1};
		MOV_F_R0_A:
			o_mc_b	=	{1'b1,2'b00,4'h0,3'b000,2'b00,4'h0,1'b0,1'b0,4'h0,4'h9,3'b100,3'd0,	1'b0,3'b000,1'b1,4'h0,1'b1,1'b1,1'b1};
		MOV_F_R1_A:
			o_mc_b	=	{1'b1,2'b00,4'h0,3'b000,2'b00,4'h0,1'b0,1'b0,4'h0,4'h9,3'b100,3'd0,	1'b0,3'b000,1'b1,4'h1,1'b1,1'b1,1'b1};
		
		MOV_F_R0_DIR:
			o_mc_b	=	{1'b0,2'b00,4'h0,3'b000,2'b00,4'h0,1'b0,1'b0,4'h0,4'h0,3'b100,3'd0,	1'b1,3'b100,1'b1,4'h8,1'b0,1'b1,1'b1};
		MOV_F_R1_DIR:
			o_mc_b	=	{1'b0,2'b00,4'h0,3'b000,2'b00,4'h0,1'b0,1'b0,4'h0,4'h0,3'b100,3'd0,	1'b1,3'b101,1'b1,4'h8,1'b0,1'b1,1'b1};
			
		MOV_F_R0_IMM:
			o_mc_b	=	{1'b0,2'b00,4'h0,3'b000,2'b00,4'h0,1'b0,1'b0,4'h1,4'h9,3'b100,3'd0,	1'b0,3'b100,1'b1,4'h8,1'b0,1'b1,1'b1};
		MOV_F_R1_IMM:
			o_mc_b	=	{1'b0,2'b00,4'h0,3'b000,2'b00,4'h0,1'b0,1'b0,4'h1,4'h9,3'b100,3'd0,	1'b0,3'b101,1'b1,4'h8,1'b0,1'b1,1'b1};

		MOV_DPTR_IMM:
			o_mc_b	=	{1'b0,2'b00,4'h0,3'b000,2'b00,4'h0,1'b0,1'b0,4'h1,4'ha,3'b000,3'd1,	1'b1,3'b111,1'b0,4'h8,1'b0,1'b1,1'b1};
		
		MOVC_A_F_DPTRPA:
			o_mc_b	=	{1'b0,2'b00,4'h0,3'b000,2'b00,4'h0,1'b0,1'b0,4'h1,4'h9,3'b000,3'd0,	1'b0,3'b111,1'b0,4'ha,1'b0,1'b0,1'b1};
		MOVC_A_F_PCPA:
			o_mc_b	=	{1'b0,2'b00,4'h0,3'b000,2'b00,4'h0,1'b0,1'b0,4'h1,4'h9,3'b000,3'd0,	1'b0,3'b111,1'b0,4'hb,1'b0,1'b0,1'b1};
		MOVX_A_F_R0:
			o_mc_b	=	{1'b0,2'b00,4'h0,3'b000,2'b00,4'h0,1'b0,1'b0,4'h0,4'h0,3'b001,3'd0,	1'b0,3'b000,1'b1,4'h0,1'b1,1'b1,1'b1};
		MOVX_A_F_R1:
			o_mc_b	=	{1'b0,2'b00,4'h0,3'b000,2'b00,4'h0,1'b0,1'b0,4'h0,4'h0,3'b001,3'd0,	1'b0,3'b000,1'b1,4'h1,1'b1,1'b1,1'b1};
		MOVX_A_F_DPTR:
			o_mc_b	=	{1'b0,2'b00,4'h0,3'b000,2'b00,4'h0,1'b0,1'b0,4'h0,4'h0,3'b000,3'd0,	1'b0,3'b111,1'b0,4'h9,1'b1,1'b0,1'b1};
		MOVX_F_R0_A:
			o_mc_b	=	{1'b1,2'b00,4'h0,3'b000,2'b00,4'h0,1'b0,1'b0,4'h0,4'h9,3'b100,3'd0,	1'b0,3'b000,1'b1,4'h0,1'b1,1'b1,1'b1};
		MOVX_F_R1_A:
			o_mc_b	=	{1'b1,2'b00,4'h0,3'b000,2'b00,4'h0,1'b0,1'b0,4'h0,4'h9,3'b100,3'd0,	1'b0,3'b000,1'b1,4'h1,1'b1,1'b1,1'b1};
		MOVX_F_DPTR_A:
			o_mc_b	=	{1'b1,2'b00,4'h0,3'b000,2'b00,4'h0,1'b0,1'b0,4'h0,4'h8,3'b100,3'd0,	1'b0,3'b111,1'b0,4'h9,1'b1,1'b0,1'b1};
		PUSH:
			o_mc_b	=	{1'b0,2'b00,4'h6,3'b010,2'b00,4'h0,1'b0,1'b0,4'h0,4'h9,3'b010,3'd3,1'b1,3'b111,1'b0,4'h8,1'b0,1'b0,1'b1};
							//The PUSH operation: 
							//	SP <- SP+1
							//	Write Direct to ram block
		POP:
			o_mc_b	=	{1'b1,2'b00,4'h6,3'b011,2'b00,4'h0,1'b0,1'b0,4'h2,4'h8,3'b010,3'd3,1'b0,3'b001,1'b1,4'h8,1'b0,1'b1,1'b1};
		XCH_A_DIR:
			o_mc_b	=	{1'b1,2'b00,4'h0,3'b000,2'b00,4'h0,1'b0,1'b0,4'h0,4'h8,3'b001,3'd5,1'b1,3'b000,1'b1,4'h8,1'b0,1'b1,1'b1};
		XCH_A_F_R0:
			o_mc_b	=	{1'b1,2'b00,4'h0,3'b000,2'b00,4'h0,1'b0,1'b0,4'h0,4'h8,3'b001,3'd5,1'b1,3'b000,1'b1,4'h0,1'b1,1'b1,1'b1};
		XCH_A_F_R1:
			o_mc_b	=	{1'b1,2'b00,4'h0,3'b000,2'b00,4'h0,1'b0,1'b0,4'h0,4'h8,3'b001,3'd5,1'b1,3'b000,1'b1,4'h1,1'b1,1'b1,1'b1};
		
							//Exchange digits
							//XCHD exchanges the lower-order nibble of the Acc (3 -0 bit) 
		XCHD_A_F_R0:
			o_mc_b	=	{1'b1,2'b00,4'h0,3'b000,2'b00,4'h0,1'b0,1'b0,4'h7,4'h8,3'b001,3'd5,1'b1,3'b000,1'b1,4'h0,1'b1,1'b1,1'b1};
		XCHD_A_F_R1:
			o_mc_b	=	{1'b1,2'b00,4'h0,3'b000,2'b00,4'h0,1'b0,1'b0,4'h7,4'h8,3'b001,3'd5,1'b1,3'b000,1'b1,4'h1,1'b1,1'b1,1'b1};
		
		SWAP_A:
			o_mc_b	=	{1'b0,2'b00,4'h0,3'b000,2'b00,4'h7,1'b0,1'b0,4'h0,4'h0,3'b010,3'd0,1'b0,3'b111,1'b0,4'h8,1'b0,1'b0,1'b0};
							//During the execution of "ADD", alg-flag must be set
		ADD_A_DIR:
			o_mc_b	=	{1'b0,2'b00,4'h5,3'b000,2'b00,4'h0,1'b0,1'b1,4'h0,4'h0,3'b010,3'd0,1'b0,3'b000,1'b1,4'h8,1'b0,1'b1,1'b1};
		ADD_A_F_R0:
			o_mc_b	=	{1'b0,2'b00,4'h5,3'b000,2'b00,4'h0,1'b0,1'b1,4'h0,4'h0,3'b010,3'd0,1'b0,3'b000,1'b1,4'h0,1'b1,1'b1,1'b1};
		ADD_A_F_R1:
			o_mc_b	=	{1'b0,2'b00,4'h5,3'b000,2'b00,4'h0,1'b0,1'b1,4'h0,4'h0,3'b010,3'd0,1'b0,3'b000,1'b1,4'h1,1'b1,1'b1,1'b1};
		ADD_A_IMM:
			o_mc_b	=	{1'b0,2'b00,4'h4,3'b000,2'b00,4'h0,1'b0,1'b1,4'h0,4'h0,3'b010,3'd0,1'b0,3'b111,1'b0,4'h8,1'b0,1'b0,1'b1};
		ADDC_A_DIR:
							//Add with carry flag (cy_q)
			o_mc_b	=	{1'b0,2'b00,4'h5,3'b000,2'b00,4'h8,1'b0,1'b1,4'h0,4'h0,3'b010,3'd0,1'b0,3'b000,1'b1,4'h8,1'b0,1'b1,1'b1};
		ADDC_A_F_R0:
			o_mc_b	=	{1'b0,2'b00,4'h5,3'b000,2'b00,4'h8,1'b0,1'b1,4'h0,4'h0,3'b010,3'd0,1'b0,3'b000,1'b1,4'h0,1'b1,1'b1,1'b1};
		ADDC_A_F_R1:
			o_mc_b	=	{1'b0,2'b00,4'h5,3'b000,2'b00,4'h8,1'b0,1'b1,4'h0,4'h0,3'b010,3'd0,1'b0,3'b000,1'b1,4'h1,1'b1,1'b1,1'b1};
		ADDC_A_IMM:
			o_mc_b	=	{1'b0,2'b00,4'h4,3'b000,2'b00,4'h8,1'b0,1'b1,4'h0,4'h0,3'b010,3'd0,1'b0,3'b111,1'b0,4'h8,1'b0,1'b0,1'b1};
		
		SUBB_A_DIR:
			o_mc_b	=	{1'b0,2'b00,4'h4,3'b000,2'b00,4'h9,1'b0,1'b1,4'h0,4'h0,3'b010,3'd0,1'b0,3'b000,1'b1,4'h8,1'b0,1'b1,1'b1};
		SUBB_A_F_R0:
			o_mc_b	=	{1'b0,2'b00,4'h5,3'b000,2'b00,4'h9,1'b0,1'b1,4'h0,4'h0,3'b010,3'd0,1'b0,3'b000,1'b1,4'h0,1'b1,1'b1,1'b1};
		SUBB_A_F_R1:
			o_mc_b	=	{1'b0,2'b00,4'h5,3'b000,2'b00,4'h9,1'b0,1'b1,4'h0,4'h0,3'b010,3'd0,1'b0,3'b000,1'b1,4'h1,1'b1,1'b1,1'b1};
		SUBB_A_IMM:
			o_mc_b	=	{1'b0,2'b00,4'h4,3'b000,2'b00,4'h9,1'b0,1'b1,4'h0,4'h0,3'b010,3'd0,1'b0,3'b111,1'b0,4'h8,1'b0,1'b0,1'b1};
		
		INC_A:
							//No flags will be affected
			o_mc_b	=	{1'b0,2'b00,4'h7,3'b000,2'b00,4'h0,1'b0,1'b0,4'h0,4'h0,3'b010,3'd0,1'b0,3'b111,1'b1,4'h8,1'b0,1'b0,1'b0};
		INC_DIR:
			o_mc_b	=	{1'b1,2'b00,4'h5,3'b010,2'b00,4'h0,1'b0,1'b0,4'h6,4'h8,3'b010,3'd5,1'b0,3'b000,1'b1,4'h8,1'b0,1'b1,1'b1};
		INC_F_R0:
			o_mc_b	=	{1'b1,2'b00,4'h5,3'b010,2'b00,4'h0,1'b0,1'b0,4'h6,4'h8,3'b010,3'd5,1'b0,3'b000,1'b1,4'h0,1'b1,1'b1,1'b1};
		INC_F_R1:
			o_mc_b	=	{1'b1,2'b00,4'h5,3'b010,2'b00,4'h0,1'b0,1'b0,4'h6,4'h8,3'b010,3'd5,1'b0,3'b000,1'b1,4'h1,1'b1,1'b1,1'b1};
		
		DEC_A:
			o_mc_b	=	{1'b0,2'b00,4'h7,3'b000,2'b00,4'h9,1'b0,1'b0,4'h0,4'h0,3'b010,3'd0,1'b0,3'b111,1'b1,4'h8,1'b0,1'b0,1'b0};
		DEC_DIR:
			o_mc_b	=	{1'b1,2'b00,4'h5,3'b011,2'b00,4'h0,1'b0,1'b0,4'h6,4'h8,3'b010,3'd5,1'b0,3'b000,1'b1,4'h8,1'b0,1'b1,1'b1};
		DEC_F_R0:
			o_mc_b	=	{1'b1,2'b00,4'h5,3'b011,2'b00,4'h0,1'b0,1'b0,4'h6,4'h8,3'b010,3'd5,1'b0,3'b000,1'b1,4'h0,1'b1,1'b1,1'b1};
		DEC_F_R1:
			o_mc_b	=	{1'b1,2'b00,4'h5,3'b011,2'b00,4'h0,1'b0,1'b0,4'h6,4'h8,3'b010,3'd5,1'b0,3'b000,1'b1,4'h1,1'b1,1'b1,1'b1};
		
		INC_DPTR:
			o_mc_b	=	{1'b0,2'b00,4'h2,3'b010,2'b00,4'h0,1'b0,1'b0,4'h0,4'h0,3'b010,3'd2,1'b1,3'b111,1'b1,4'h8,1'b0,1'b0,1'b0};
		
		ANL_A_DIR:
			o_mc_b	=	{1'b0,2'b00,4'h5,3'b000,2'b00,4'h1,1'b0,1'b0,4'h0,4'h0,3'b010,3'd0,1'b0,3'b000,1'b1,4'h8,1'b0,1'b1,1'b1};
		ANL_A_F_R0:
			o_mc_b	=	{1'b0,2'b00,4'h5,3'b000,2'b00,4'h1,1'b0,1'b0,4'h0,4'h0,3'b010,3'd0,1'b0,3'b000,1'b1,4'h0,1'b1,1'b1,1'b1};
		ANL_A_F_R1:
			o_mc_b	=	{1'b0,2'b00,4'h5,3'b000,2'b00,4'h1,1'b0,1'b0,4'h0,4'h0,3'b010,3'd0,1'b0,3'b000,1'b1,4'h1,1'b1,1'b1,1'b1};
		ANL_A_IMM:
			o_mc_b	=	{1'b0,2'b00,4'h4,3'b000,2'b00,4'h1,1'b0,1'b0,4'h0,4'h0,3'b010,3'd0,1'b0,3'b111,1'b0,4'h8,1'b0,1'b0,1'b1};
		ANL_DIR_A:
			o_mc_b	=	{1'b1,2'b00,4'h5,3'b000,2'b00,4'h1,1'b0,1'b0,4'h6,4'h8,3'b010,3'd5,1'b0,3'b000,1'b1,4'h8,1'b0,1'b1,1'b1};
		ANL_DIR_IMM:
			o_mc_b	=	{1'b0,2'b00,4'h0,3'b000,2'b00,4'h0,1'b0,1'b0,4'h0,4'h0,3'b001,3'd5,1'b1,3'b000,1'b1,4'h8,1'b0,1'b1,1'b1};
		
		ORL_A_DIR:
			o_mc_b	=	{1'b0,2'b00,4'h5,3'b000,2'b00,4'h3,1'b0,1'b0,4'h0,4'h0,3'b010,3'd0,1'b0,3'b000,1'b1,4'h8,1'b0,1'b1,1'b1};
		ORL_A_F_R0:
			o_mc_b	=	{1'b0,2'b00,4'h5,3'b000,2'b00,4'h3,1'b0,1'b0,4'h0,4'h0,3'b010,3'd0,1'b0,3'b000,1'b1,4'h0,1'b1,1'b1,1'b1};
		ORL_A_F_R1:
			o_mc_b	=	{1'b0,2'b00,4'h5,3'b000,2'b00,4'h3,1'b0,1'b0,4'h0,4'h0,3'b010,3'd0,1'b0,3'b000,1'b1,4'h1,1'b1,1'b1,1'b1};
		ORL_A_IMM:
			o_mc_b	=	{1'b0,2'b00,4'h4,3'b000,2'b00,4'h3,1'b0,1'b0,4'h0,4'h0,3'b010,3'd0,1'b0,3'b111,1'b0,4'h8,1'b0,1'b0,1'b1};
		ORL_DIR_A:
			o_mc_b	=	{1'b1,2'b00,4'h5,3'b000,2'b00,4'h3,1'b0,1'b0,4'h6,4'h8,3'b010,3'd5,1'b0,3'b000,1'b1,4'h8,1'b0,1'b1,1'b1};
		ORL_DIR_IMM:
			o_mc_b	=	{1'b0,2'b00,4'h0,3'b000,2'b00,4'h0,1'b0,1'b0,4'h0,4'h0,3'b001,3'd5,1'b1,3'b000,1'b1,4'h8,1'b0,1'b1,1'b1};
		
		XRL_A_DIR:
			o_mc_b	=	{1'b0,2'b00,4'h5,3'b000,2'b00,4'h2,1'b0,1'b0,4'h0,4'h0,3'b010,3'd0,1'b0,3'b000,1'b1,4'h8,1'b0,1'b1,1'b1};
		XRL_A_F_R0:
			o_mc_b	=	{1'b0,2'b00,4'h5,3'b000,2'b00,4'h2,1'b0,1'b0,4'h0,4'h0,3'b010,3'd0,1'b0,3'b000,1'b1,4'h0,1'b1,1'b1,1'b1};
		XRL_A_F_R1:
			o_mc_b	=	{1'b0,2'b00,4'h5,3'b000,2'b00,4'h2,1'b0,1'b0,4'h0,4'h0,3'b010,3'd0,1'b0,3'b000,1'b1,4'h1,1'b1,1'b1,1'b1};
		XRL_A_IMM:
			o_mc_b	=	{1'b0,2'b00,4'h4,3'b000,2'b00,4'h2,1'b0,1'b0,4'h0,4'h0,3'b010,3'd0,1'b0,3'b111,1'b0,4'h8,1'b0,1'b0,1'b1};
		XRL_DIR_A:
			o_mc_b	=	{1'b1,2'b00,4'h5,3'b000,2'b00,4'h2,1'b0,1'b0,4'h6,4'h8,3'b010,3'd5,1'b0,3'b000,1'b1,4'h8,1'b0,1'b1,1'b1};
		XRL_DIR_IMM:
			o_mc_b	=	{1'b0,2'b00,4'h0,3'b000,2'b00,4'h2,1'b0,1'b0,4'h0,4'h0,3'b001,3'd5,1'b1,3'b000,1'b1,4'h8,1'b0,1'b1,1'b1};
		
		CLR_A:
			o_mc_b	=	{1'b0,2'b00,4'h0,3'b000,2'b00,4'h0,1'b0,1'b0,4'h0,4'h0,3'b111,3'd0,1'b0,3'b111,1'b0,4'h8,1'b0,1'b0,1'b0};
		CPL_A:
			o_mc_b	=	{1'b0,2'b00,4'h0,3'b000,2'b00,4'h5,1'b0,1'b0,4'h0,4'h0,3'b010,3'd0,1'b0,3'b111,1'b0,4'h8,1'b0,1'b0,1'b0};
		RL_A:
			o_mc_b	=	{1'b0,2'b00,4'h0,3'b000,2'b00,4'h4,1'b0,1'b0,4'h0,4'h0,3'b010,3'd0,1'b0,3'b111,1'b0,4'h8,1'b0,1'b0,1'b0};
		RLC_A:
			o_mc_b	=	{1'b0,2'b00,4'h0,3'b000,2'b00,4'ha,1'b0,1'b1,4'h0,4'h0,3'b010,3'd0,1'b0,3'b111,1'b0,4'h8,1'b0,1'b0,1'b0};
							//RLC: Rotate accumulator left through carry flag
							//A6 ... A0 CY; CY <- A0;
		RR_A:
			o_mc_b	=	{1'b0,2'b00,4'h0,3'b000,2'b00,4'h6,1'b0,1'b0,4'h0,4'h0,3'b010,3'd0,1'b0,3'b111,1'b0,4'h8,1'b0,1'b0,1'b0};
		RRC_A:
			o_mc_b	=	{1'b0,2'b00,4'h0,3'b000,2'b00,4'hb,1'b0,1'b1,4'h0,4'h0,3'b010,3'd0,1'b0,3'b111,1'b0,4'h8,1'b0,1'b0,1'b0};
			
		LCALL:
			o_mc_b	=	{1'b1,2'b00,4'h6,3'b010,2'b00,4'h0,1'b0,1'b0,4'h4,4'hb,3'b010,3'd3,1'b1,3'b111,1'b0,4'h8,1'b0,1'b1,1'b1};
							//LCALL:
							//PC <- PC+3
							//PUSH PCL
							//PUSH PCH
							//LOAD TARGET PC
		RET:
			o_mc_b	=	{1'b0,2'b00,4'h6,3'b011,2'b00,4'h0,1'b0,1'b0,4'h0,4'h0,3'b010,3'd3,1'b1,3'b111,1'b0,4'hd,1'b1,1'b0,1'b1};
							//RET:
							//POP PCH
							//POP PCL
							//LOAD TARGET PC
		LJMP:
			o_mc_b	=	{1'b0,2'b10,4'h0,3'b000,2'b00,4'b1111,1'b0,1'b0,4'h0,4'h0,3'b100,3'd0,1'b0,3'b111,1'b0,4'h8,1'b0,1'b1,1'b1};
		SJMP,JZ,JNZ:
			o_mc_b	=	{1'b0,2'b10,4'h0,3'b000,2'b01,4'b0101,1'b0,1'b0,4'h4,4'hb,3'b100,3'd0,1'b0,3'b111,1'b0,4'h8,1'b0,1'b0,1'b1};
		JMP:
			o_mc_b	=	{1'b0,2'b10,4'h0,3'b000,2'b10,4'b0101,1'b0,1'b0,4'h4,4'hb,3'b100,3'd0,1'b0,3'b111,1'b0,4'h8,1'b0,1'b0,1'b0};
		CJNE_A_DIR:
			o_mc_b	=	{1'b0,2'b00,4'h0,3'b000,2'b00,4'b0000,1'b0,1'b0,4'h0,4'h0,3'b100,3'd0,1'b1,3'b000,1'b1,4'h8,1'b0,1'b1,1'b1};
		
		NOP:
			o_mc_b	=	{1'b0,2'b00,4'h0,3'b000,2'b00,4'h0,1'b0,1'b0,4'h0,4'h0,3'b100,3'd0,1'b0,3'b000,1'b0,4'h8,1'b0,1'b0,1'b0};
		default:
			o_mc_b	=	{1'b0,2'b00,4'h0,3'b000,2'b00,4'h0,1'b0,1'b0,4'h0,4'h0,3'b100,3'd0,	1'b0,3'b000,1'b0,4'h8,1'b0,1'b0,1'b0};
	endcase
else if(i_multi_cycle_times == 2'b01)
	casez(i_instr_buf)	
		MOV_DIR1_DIR2:
			o_mc_b	=	{1'b1,2'b00,4'h0,3'b000,2'b00,4'h0,1'b0,1'b0,4'h1,4'h9,3'b100,3'd0,	1'b0,3'b111,1'b0,4'hc,1'b1,1'b0,1'b1};
		MOV_DIR_F_R0,MOV_DIR_F_R1:
			o_mc_b	=	{1'b1,2'b00,4'h0,3'b000,2'b00,4'h0,1'b0,1'b0,4'h1,4'h9,3'b100,3'd0,	1'b0,3'b111,1'b0,4'hc,1'b1,1'b0,1'b1};
		MOV_F_R0_DIR,MOV_F_R0_DIR:
			o_mc_b	=	{1'b1,2'b00,4'h0,3'b000,2'b00,4'h0,1'b0,1'b0,4'h1,4'h9,3'b100,3'd0,	1'b0,3'b010,1'b1,4'hc,1'b1,1'b1,1'b1};
		MOV_DPTR_IMM:
			o_mc_b	=	{1'b0,2'b00,4'h0,3'b000,2'b00,4'h0,1'b0,1'b0,4'h1,4'ha,3'b001,3'd2,	1'b0,3'b111,1'b0,4'h8,1'b0,1'b0,1'b0};
		PUSH:
			o_mc_b	=	{1'b1,2'b00,4'h0,3'b000,2'b00,4'h0,1'b0,1'b0,4'h1,4'hb,3'b100,3'd0,	1'b0,3'b111,1'b0,4'hc,1'b1,1'b0,1'b1};
		XCH_A_DIR,XCH_A_F_R0,XCH_A_F_R1:
			o_mc_b	=	{1'b0,2'b00,4'h0,3'b000,2'b00,4'h0,1'b0,1'b0,4'h0,4'h0,3'b110,3'd0,1'b0,3'b111,1'b0,4'h8,1'b0,1'b0,1'b0};
		XCHD_A_F_R0,XCHD_A_F_R1:
			o_mc_b	=	{1'b0,2'b00,4'h0,3'b000,2'b00,4'h0,1'b0,1'b0,4'h0,4'h0,3'b110,3'd6,1'b0,3'b111,1'b0,4'h8,1'b0,1'b0,1'b0};
		INC_DPTR:
			o_mc_b	=	{1'b0,2'b00,4'h3,3'b111,2'b00,4'h0,1'b0,1'b0,4'h0,4'h0,3'b010,3'd1,1'b0,3'b111,1'b1,4'h8,1'b0,1'b0,1'b0};
		ANL_DIR_IMM:
			o_mc_b	=	{1'b1,2'b00,4'h5,3'b100,2'b00,4'h1,1'b0,1'b0,4'h6,4'h8,3'b010,3'd5,1'b0,3'b111,1'b0,4'h8,1'b0,1'b1,1'b0};
		ORL_DIR_IMM:
			o_mc_b	=	{1'b1,2'b00,4'h5,3'b100,2'b00,4'h3,1'b0,1'b0,4'h6,4'h8,3'b010,3'd5,1'b0,3'b111,1'b0,4'h8,1'b0,1'b1,1'b0};
		XRL_DIR_IMM:
			o_mc_b	=	{1'b1,2'b00,4'h5,3'b100,2'b00,4'h2,1'b0,1'b0,4'h6,4'h8,3'b010,3'd5,1'b0,3'b111,1'b0,4'h8,1'b0,1'b1,1'b0};
		LCALL:
			o_mc_b	=	{1'b1,2'b00,4'h6,3'b010,2'b00,4'h0,1'b0,1'b0,4'h3,4'hb,3'b010,3'd3,1'b1,3'b111,1'b0,4'h8,1'b0,1'b0,1'b0};
		RET:
			o_mc_b	=	{1'b0,2'b00,4'h6,3'b011,2'b00,4'h0,1'b0,1'b0,4'h0,4'h0,3'b010,3'd3,1'b1,3'b001,1'b1,4'h8,1'b0,1'b1,1'b0};
		CJNE_A_DIR:
			o_mc_b	=	{1'b0,2'b10,4'h0,3'b000,2'b01,4'b0101,1'b0,1'b0,4'h4,4'hb,3'b100,3'd0,1'b0,3'b111,1'b0,4'h8,1'b0,1'b0,1'b1};
		default:
			o_mc_b	=	{1'b0,2'b00,4'h0,3'b000,2'b00,4'h0,1'b0,1'b0,4'h0,4'h0,3'b100,3'd0,	1'b0,3'b000,1'b0,4'h8,1'b0,1'b0,1'b0};
	endcase
else if(i_multi_cycle_times == 2'b10)
		casez(i_instr_buf)	
		LCALL,RET:
			o_mc_b	=	{1'b0,2'b10,4'h0,3'b000,2'b00,4'b1111,1'b0,1'b0,4'h0,4'h0,3'b100,3'd0,1'b0,3'b111,1'b0,4'h8,1'b0,1'b0,1'b0};
		default:
			o_mc_b	=	{1'b0,2'b00,4'h0,3'b000,2'b00,4'h0,1'b0,1'b0,4'h0,4'h0,3'b100,3'd0,	1'b0,3'b000,1'b0,4'h8,1'b0,1'b0,1'b0};
	endcase
else begin
			o_mc_b	=	{1'b0,2'b00,4'h0,3'b000,2'b00,4'h0,1'b0,1'b0,4'h0,4'h0,3'b100,3'd0,	1'b0,3'b000,1'b0,4'h8,1'b0,1'b0,1'b0};
end


endmodule