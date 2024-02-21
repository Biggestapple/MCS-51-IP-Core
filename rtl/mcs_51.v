//----------------------------------------------------------------------------------------------------------
//	FILE: 		mcs_51.v
// 	AUTHOR:		Biggest_apple
// 	
//	ABSTRACT:	This's a mcs-51 ip core
// 	KEYWORDS:	fpga, basic module,signal process
// 
// 	MODIFICATION HISTORY:
//	$Log$
//			Biggest_apple 		2023.12.20		Build
//								2024.1.1		The first test
//								2024.2.2		Finished all the micocode
//								2024.2.11		Add interrupt relevant circuit
//								2024.2.19		Improve micocode structure
//								2024.2.20		Fixed bugs in multi-cycles instructions
//-----------------------------------------------------------------------------------------------------------
module	mcs_51(
	input		clk,
	input		sys_rst_n,
	
	output			[15:0]	mem_addr,
	input			[7:0]	mem_rdata,
	//output	reg		[7:0]	mem_wdata,
	
	//output		we_n,
	//output		rd_n,
	output	reg	psen_n,
	
	input	reg	int_n_0,
	
	input	reg	int_n_1,
	
	output	tx,
	input	rx,
	inout	[7:0]		p1,
	inout	[7:0]		p2,
	
	input		ready_in
	
);
reg			psen_n_cologic;
reg			[7:0]		mem_wdata;
reg			we_n;
reg			rd_n;
reg			[7:0]		c_mem_rdata;

							//Internal 128 bytes ram and external 128 bytes ram claim
reg			[7:0]		i_ram		[0:127];
reg			[7:0]		e_ram		[0:127];
							//Opcode
localparam	[4:0]		MOV_A_RN	=	5'b1110_1,	MOV_RN_A	=	5'b1111_1,				MOV_DIR_RN	=5'b1000_1,
						XCH_A_RN	=	5'b1100_1,	ADD_A_RN	=	5'b0010_1,				ADDC_A_RN	=5'b0011_1,
						SUBB_A_RN	=	5'b1001_1,	INC_RN		=	5'b0000_1,				DEC_RN		=5'b0001_1,
						ANL_A_RN	=	5'b0101_1,	ORL_A_RN	=	5'b0100_1,				XRL_A_RN	=5'b0110_1,	
						CJNE_RN_IMM	=	5'b1011_1,	DJNZ_RN		=	5'b1101_1,				MOV_RN_DIR	=5'b1010_1,
						MOV_RN_IMM	=	5'b0111_1
						;
localparam	[7:0]		INTERRUPT_P0=	8'hFA;
localparam	[4:0]		ACALL		=	5'b10001,	AJMP		=	5'b00001;					
localparam	[7:0]		MOV_A_DIR	=	8'hE5,MOV_A_F_R0 	=8'hE6,	MOV_A_F_R1 	=8'hE7,		MOV_A_IMM	 	=8'h74,
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
							//Micro-code register

reg		[3:0]	t_p_q;
reg		[3:0]	t_p_d;
							//Timing-phase
localparam		S1_0	=4'd0,
				S1_1	=4'd1,
				S2_0	=4'd2,
				S2_1	=4'd3,
				S3_0	=4'd4,
				S3_1	=4'd5,
				S4_0	=4'd6,
				S4_1	=4'd7,
				S5_0	=4'd8,
				S5_1	=4'd9,
				S6_0	=4'd10,
				S6_1	=4'd11,
				S7_0	=4'd12,
				S7_1	=4'd13,
				S8_0	=4'd14,
				S8_1	=4'd15;
							//User register Here
reg		[7:0]	ax_q;
wire	[7:0]	reg_w_d;
reg		[7:0]	bx_q;
reg		[7:0]	sx_q;		//For bit-operation's intermediate variables
reg		[7:0]	dptrh_q;
reg		[7:0]	dptrl_q;
reg		[7:0]	sp_q;
							//Processor statue flag
reg		cy_q;
reg		cy_d;
reg		pcl_cy;
reg		ov_q;
reg		ov_d;
reg		f0_q;
							//reg		f0_d;


reg		ac_q;
reg		ac_d;
reg		pr_q;

reg		zo_q;
reg		zo_d;

reg		[7:0]	pcl_q;
reg		[7:0]	pcl_d;
reg		[7:0]	pch_q;
reg		[7:0]	pch_d;

reg		[15:0]	mem_addr_q;
reg		[15:0]	mem_addr_d;

reg		rs0_q;
reg		rs1_q;
reg		rs0_d;
reg		rs1_d;

wire	[7:0]	r0_w;
wire	[7:0]	r1_w;
wire	[7:0]	r2_w;
wire	[7:0]	r3_w;

wire	[7:0]	r4_w;
wire	[7:0]	r5_w;
wire	[7:0]	r6_w;
wire	[7:0]	r7_w;

							//Micro-code statue flag

reg		[7:0]	instr_buffer_q;
reg		[7:0]	s2_data_buffer_q;
reg		[7:0]	instr_buffer_d;
reg		[7:0]	s2_data_buffer_d;
reg		[7:0]	s3_data_buffer_q;
reg		[7:0]	s3_data_buffer_d;

reg		is_two_word;
wire	is_two_word_d;
reg		is_three_word;
wire	is_three_word_d;

reg		is_multi_cycles;
reg		[1:0]		multi_cycle_times;
							//Max instruction cycles --> 4 cycles
							//Microcode rom unit
reg		[43:0]		mc_b;	
							//Internal Wire connection
reg		is_base_pch;
reg		is_base_pcl;
reg		is_jump_flag;
reg		is_call;
reg		is_jump_active;
reg		[1:0]		pc_jgen_sel;
							//Interrupt related Wire
wire	[7:0]		mc51_int_n;
wire	is_interrupt_cycle		=	1'b0;
reg		is_interrupt_ocpt;
wire	intr_excu_done;
wire	intr_flag;
localparam		INT_VECTOR_0	=	16'h0003,
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
reg		s2_rd_ram_nprg;
reg		s3_rd_ram_nprg;
reg		is_s2_fetch;
reg		is_s3_fetch;

wire	[7:0]	mem_wdata_ss;
reg		[3:0]	mem_wdata_mux_sel;
reg		[2:0]	reg_w_mux_ss;
reg		[2:0]	reg_tar_ss;
reg		[3:0]	s2_mem_addr_sel;
reg		[2:0]	s3_mem_addr_sel;
reg		[3:0]	s6_mem_addr_sel;
reg		[1:0]	pch_w_sel;
reg		[1:0]	pcl_w_sel;

reg		pro_flag_update;
reg		ax_comp_o;			//This one is for "SUB" instruction

reg		[3:0]	bit_sel;
reg		bit_oper_flag;
reg		set_or_clr;
reg		[2:0]	bit_mode_sel;
wire	set_or_clr_temp;


reg		[7:0]	sx_d;		//Shadow register-- >not visible to the user
reg		cy_set;
reg		ac_set;
reg		ov_set;
reg		zo_set;
reg		pr_set;
							//reg		f0_set;

wire	[7:0]	alu_in_0;
wire	[7:0]	alu_in_1;
reg		[3:0]	alu_mode_sel;	
wire			alu_in_cy;
reg		[2:0]	alu_in_0_mux_sel;
reg		[3:0]	alu_in_1_mux_sel;
							//SFR	register	and 	control

wire	is_wPSW;
wire	is_wAcc;
wire	is_wB;
wire	is_wSp;
wire	is_wdptrh;
wire	is_wdptrl;
							//Group 0
/*
reg		[7:0]	PSW;
reg		[7:0]	Acc;
reg		[7:0]	B;
*/
							//Group 1
reg		[7:0]	IP;
reg		[7:0]	P0_r;
reg		[7:0]	P1_r;
reg		[7:0]	P2_r;
reg		[7:0]	P3_r;

reg		[7:0]	IE;
reg		[7:0]	SCON;
reg		[7:0]	TCON;
							//Interrupt relevant signals
reg		[15:0]		int_jp_addr_q;
reg		[15:0]		int_jp_addr_d;
wire	EA			=IE[7];
wire	E_Reserved1	=IE[6];
wire	E_Reserved0	=IE[5];
wire	ES			=IE[4];
wire	ET1			=IE[3];
wire	EX1			=IE[2];
wire	ET0			=IE[1];
wire	EX0			=IE[0];
wire	[2:0]	IP_Reserved		=	IP[7:5];
wire	PS			=IP[4];
wire	PT1			=IP[3];
wire	PX1			=IP[2];
wire	PT0			=IP[1];
wire	PX0			=IP[0];
wire	int_in_ex0;
wire	int_in_ex1;
wire	int_in_et0;
wire	int_in_et1;
wire	int_in_es;
reg		lo_priority_int_on;
reg		hi_priority_int_on;	//Only "RETI" instruction can influence these two flags
wire	int_in_ss_0;
wire	int_in_ss_1;
wire	int_in_ss_2;
wire	int_in_ss_3;
wire	int_in_ss_4;
wire	int_in_sp_0;
wire	int_in_sp_1;
wire	int_in_sp_2;
wire	int_in_sp_3;
wire	int_in_sp_4;
assign	int_in_ss_0	=	int_in_ex0 &EX0 &EA,
		int_in_ss_1	=	int_in_et0 &ET0 &EA,
		int_in_ss_2	=	int_in_ex1 &EX1 &EA,
		int_in_ss_3	=	int_in_et1 &ET1 &EA,
		int_in_ss_4	=	int_in_es  &ES  &EA;
assign	int_in_sp_0	=	int_in_ss_0 &PX0,
		int_in_sp_1	=	int_in_ss_1	&PT0,
		int_in_sp_2	=	int_in_ss_2	&PX1,
		int_in_sp_3	=	int_in_ss_3	&PT1,
		int_in_sp_4	=	int_in_ss_4 &PS ;
							/*
		alu_mode_sel
		4'h0	--	>	SUM
		4'h1	--	>	ANDS							
		4'h2	--	>	XOR
		4'h3	--	>	OR
		4'h4	--	>	SRCS
		4'h5	--	>	SUM With Carry
							*/
localparam	[3:0]	SUM			=4'h0,
					ANDS		=4'h1,
					XOR			=4'h2,
					OR			=4'h3,
					RL			=4'h4,
					CPL			=4'h5,
					RR			=4'h6,
					SWAP		=4'h7;
reg		[7:0]	alu_o;
							//128 VALID INSTRUCTIONS

wire  IS_VALID_OPCODE 		=																													
	(
		(instr_buffer_q[7:3]	== MOV_A_RN	) ||(instr_buffer_q	==MOV_A_DIR)	||(instr_buffer_q	==MOV_A_F_R0)	||(instr_buffer_q	==MOV_A_F_R1)			||	
		(instr_buffer_q	== MOV_A_IMM) ||(instr_buffer_q[7:3]	==MOV_RN_A)	||(instr_buffer_q[7:3]	==ADDC_A_RN)	||(instr_buffer_q	==MOV_RN_DIR)			||	
		(instr_buffer_q	== MOV_RN_IMM) ||(instr_buffer_q	==MOV_DIR_A)	||(instr_buffer_q[7:3]	==MOV_DIR_RN)	||(instr_buffer_q	==MOV_DIR1_DIR2)		||	
		(instr_buffer_q	== MOV_DIR_F_R0) ||(instr_buffer_q	==MOV_DIR_F_R1)	||(instr_buffer_q	==MOV_DIR_IMM)	||(instr_buffer_q	==MOV_F_R0_A)				||	
		(instr_buffer_q	== MOV_F_R1_A) ||(instr_buffer_q	==MOV_F_R0_DIR)	||(instr_buffer_q	==MOV_F_R1_DIR)	||(instr_buffer_q	==MOV_F_R0_IMM)				||	
		(instr_buffer_q	== MOV_DPTR_IMM) ||(instr_buffer_q	==MOVC_A_F_DPTRPA)	||(instr_buffer_q	==MOVC_A_F_PCPA)	||(instr_buffer_q	==MOVX_A_F_R0)		||	
		(instr_buffer_q	== MOVX_A_F_R1) ||(instr_buffer_q	==MOVX_A_F_DPTR)	||(instr_buffer_q	==MOVX_F_R0_A)	||(instr_buffer_q	==MOVX_F_R1_A)			||	
		
		(instr_buffer_q	== MOVX_F_DPTR_A) ||(instr_buffer_q	==PUSH)	||(instr_buffer_q	==POP)	||(instr_buffer_q	==XCHD_A_F_R0)								||	
		(instr_buffer_q	== XCHD_A_F_R1) ||(instr_buffer_q	==XCH_A_DIR)	||(instr_buffer_q	==XCH_A_F_R0)	||(instr_buffer_q	==XCH_A_F_R1)				||	
		(instr_buffer_q[7:3]	== XCH_A_RN) ||(instr_buffer_q	==SWAP)	||(instr_buffer_q[7:3]	==ADD_A_RN)	||(instr_buffer_q	==ADD_A_DIR)					||	
		
		(instr_buffer_q	== ADD_A_F_R0) ||(instr_buffer_q	==ADD_A_F_R1)	||(instr_buffer_q	==ADD_A_IMM)	||(instr_buffer_q	==ADDC_A_DIR)				||	
		(instr_buffer_q	== ADDC_A_F_R0) ||(instr_buffer_q	==ADDC_A_F_R1)	||(instr_buffer_q	==ADDC_A_IMM)	||(instr_buffer_q	==SUBB_A_DIR)				||	
		(instr_buffer_q	== SUBB_A_F_R1) ||(instr_buffer_q	==SUBB_A_F_R0)	||(instr_buffer_q	==SUBB_A_IMM)	||(instr_buffer_q	==INC_A)					||	
		
		(instr_buffer_q	== INC_DIR) ||(instr_buffer_q	==INC_F_R0)	||(instr_buffer_q	==INC_F_R1)	||(instr_buffer_q	==DEC_A)								||	
		(instr_buffer_q	== DEC_DIR) ||(instr_buffer_q	==DEC_F_R0)	||(instr_buffer_q	==DEC_F_R1)	||(instr_buffer_q	==INC_DPTR)								||	
		(instr_buffer_q	== MUL_AB) ||(instr_buffer_q	==DIV_AB)	||(instr_buffer_q	==DA_A)	||(instr_buffer_q	==ANL_A_DIR)								||	
		(instr_buffer_q	== ANL_A_F_R0) ||(instr_buffer_q	==ANL_A_F_R1)	||(instr_buffer_q	==ANL_A_IMM)	||(instr_buffer_q	==ANL_DIR_A)				||	
		(instr_buffer_q	== ANL_DIR_IMM) ||(instr_buffer_q	==ORL_A_DIR)	||(instr_buffer_q	==ORL_A_F_R0)	||(instr_buffer_q	==ORL_A_F_R1)				||	
	
		(instr_buffer_q	== ORL_A_IMM) ||(instr_buffer_q	==ORL_DIR_A)	||(instr_buffer_q	==ORL_DIR_IMM)	||(instr_buffer_q	==XRL_A_DIR)					||	
		(instr_buffer_q	== XRL_A_F_R0) ||(instr_buffer_q	==XRL_A_F_R1)	||(instr_buffer_q	==XRL_A_IMM)	||(instr_buffer_q	==XRL_DIR_A)				||	
		(instr_buffer_q	== XRL_DIR_IMM) ||(instr_buffer_q	==CPL_A)	||(instr_buffer_q	==RL_A)	||(instr_buffer_q	==RLC_A)								||	
		(instr_buffer_q	== RR_A) ||(instr_buffer_q	==RRC_A)	||(instr_buffer_q	==LCALL)	||(instr_buffer_q	==RET)										||	
		(instr_buffer_q	== RETI) ||(instr_buffer_q	==LJMP)	||(instr_buffer_q	==SJMP)	||(instr_buffer_q	==JMP)												||	
		(instr_buffer_q	== JZ) ||(instr_buffer_q	==JNZ)	||(instr_buffer_q	==CJNE_A_DIR)	||(instr_buffer_q	==CJNE_A_IMM)								||	
		(instr_buffer_q	== CJNE_F_R0) ||(instr_buffer_q	==CJNE_F_R1)	||									(instr_buffer_q	==NOP)								||	
		(instr_buffer_q	== CLR_C) ||(instr_buffer_q	==CLR_BIT)	||(instr_buffer_q	==SETB_C)	||(instr_buffer_q	==SETB_BIT)									||	
		(instr_buffer_q	== CPL_C) ||(instr_buffer_q	==CPL_BIT)	||(instr_buffer_q	==ANL_C_BIT)	||(instr_buffer_q	==ANL_C_NBIT)							||	
		(instr_buffer_q	== ORL_C_BIT) ||(instr_buffer_q	==ORL_C_NBIT)	||(instr_buffer_q	==MOV_C_BIT)	||(instr_buffer_q	==MOV_BIT_C)					||	
		(instr_buffer_q	== JC) ||(instr_buffer_q	==JNC)	||(instr_buffer_q	==JB)	||(instr_buffer_q	==JNB)												||	
		(instr_buffer_q	== JBC) ||(instr_buffer_q[7:3] ==SUBB_A_RN)||(instr_buffer_q[7:3] ==INC_RN)||(instr_buffer_q[7:3] ==DEC_RN)								||	
		(instr_buffer_q[7:3] ==ANL_A_RN)||(instr_buffer_q[7:3] ==ORL_A_RN)||(instr_buffer_q[7:3] ==XRL_A_RN)||(instr_buffer_q[7:3] ==CJNE_RN_IMM)				||	
		(instr_buffer_q[7:3] ==DJNZ_RN) ||(instr_buffer_q[7:3] ==MOV_RN_DIR) ||(instr_buffer_q[7:3] ==ACALL)||(instr_buffer_q[7:3] ==AJMP)
		);
		
always @(posedge clk)
	if(!sys_rst_n) begin
		instr_buffer_q		<=	8'b0;
		s2_data_buffer_q		<=	8'b0;
		s3_data_buffer_q		<=	8'b0;

		t_p_q				<=	S1_0;
		mem_wdata			<=	8'b0;
		int_jp_addr_q		<=	16'h0000;
	end
	else begin
		t_p_q				<=t_p_d;
		instr_buffer_q		<=instr_buffer_d;
		s2_data_buffer_q	<=s2_data_buffer_d;
		s3_data_buffer_q	<=s3_data_buffer_d;
		
		mem_wdata		<=(t_p_q == S6_0) ? mem_wdata_ss: mem_wdata;
		int_jp_addr_q		<=int_jp_addr_d;
	end
always @(negedge clk)
	if(!sys_rst_n)
		psen_n	<=	1'b1;
	else
		psen_n	<=	psen_n_cologic;
always @(*) begin	
	t_p_d	=	S1_0;		
	psen_n_cologic	=	1'b1;
	we_n	=	1'b1;
	rd_n	=	1'b1;
	pch_d	=	pch_q;
	pcl_d	=	pcl_q;
	int_jp_addr_d	=	int_jp_addr_q;
	
	instr_buffer_d		=	instr_buffer_q;
	s2_data_buffer_d	=	s2_data_buffer_q;
	s3_data_buffer_d	=	s3_data_buffer_q;
	case(t_p_q)
		S1_0:				// Beside getting the current instruction 
							// in s1 ~s2 phase,we should generate the next PC value
			begin
				if(is_interrupt_cycle)
					t_p_d	=	S4_0;
				else begin
					t_p_d	=	(ready_in) ? S1_1:S1_0;
					instr_buffer_d	=	c_mem_rdata;
					psen_n_cologic	=	1'b0;
					pcl_d	=	alu_o;
				end
			end
		S1_1:
			begin
				t_p_d	=	(is_s2_fetch) ?S2_0 :S4_0;
				psen_n_cologic	=	1'b0;
				pch_d	=	alu_o;
			end
		
		S2_0: begin
		/*
				case(m_op[15:13])
					3'd0:
						begin
							//Fetch the data from prg_rom
							alu_in_0_mux_sel	=2'b10;
							alu_in_1_mux_sel	=3'b000;
							psen_n_cologic	=	1'b0;
							rd_n	=	1'b1;
						end
					3'd1:
						begin
							//Fetch the data from ram
							psen_n_cologic	=	1'b1;
							rd_n	=	1'b0;
						end
			
				endcase
		*/
		/*
				t_p_d	=	(ready_in) ? S2_1:S2_0;
		*/
				if(~s2_rd_ram_nprg)
					begin
						psen_n_cologic	=	1'b0;
						rd_n	=	1'b1;
						pcl_d	=	(s2_mem_addr_sel == 4'h8) ?alu_o :pcl_q;
							//In this case PC value will add "1" automatically
					end
				else begin
						psen_n_cologic	=	1'b1;
						rd_n	=	1'b0;
				
					end
				t_p_d	=	(ready_in) ? S2_1:S2_0;
				s2_data_buffer_d	=	(ready_in) ?c_mem_rdata:s2_data_buffer_q;
			end
		S2_1:begin
				psen_n_cologic	=	1'b1;
				rd_n	=	1'b1;
				t_p_d	=	(is_s3_fetch) ?S3_0:S4_0;
				if(~s2_rd_ram_nprg)
					pch_d	=	(s2_mem_addr_sel == 4'h8) ?alu_o :pch_q;
			end
		S3_0:
			begin
				if(~s3_rd_ram_nprg)
					begin
						psen_n_cologic	=	1'b0;
						rd_n	=	1'b1;
						pcl_d	=	alu_o;
					end
				else begin
						psen_n_cologic	=	1'b1;
						rd_n	=	1'b0;
					end
				t_p_d	=	(ready_in) ? S3_1:S3_0;
				s3_data_buffer_d	=	(ready_in) ?c_mem_rdata:s3_data_buffer_q;
			end
		S3_1: begin
				psen_n_cologic	=	1'b1;
				rd_n	=	1'b1;
				t_p_d	=S4_0;
				if(~s3_rd_ram_nprg)
					pch_d	=	alu_o;
			end
		S4_0:				
			t_p_d	=	S4_1;
		S4_1:
			t_p_d	=	S5_0;
		S5_0:
										//S5 stage does nothing but acc = acc + 8'b0
			t_p_d	=	S5_1;
		S5_1:
			t_p_d	=	S6_0;
										//Note S4 and S5 phase is used for arithmetic operation
		
		S6_0:
			begin
				t_p_d	=	S6_1;
				if(is_jump_flag && is_jump_active) 
					pcl_d	=	(pcl_w_sel == 2'b00) ? pcl_q:
								(pcl_w_sel == 2'b01) ? alu_o:
								(pcl_w_sel == 2'b10) ? int_jp_addr_q[7:0]:
								pcl_q;
			end
		S6_1: 
			begin
										//Write the data to ram
				if(mc_b[43]) begin
					t_p_d	=	(ready_in) ? S1_0:S8_1;
					we_n	=	1'b0;
				end
				else if(is_multi_cycles)					
										//If the instruction needs two cycles?
					t_p_d	=	S2_0;
				
				else
					t_p_d	=	S7_0;
										//We can calculate the target address in one cpu cycle
				if(is_jump_flag && is_jump_active)
					pch_d	=	(pch_w_sel == 2'b00) ? pch_q:
								(pch_w_sel == 2'b01) ? alu_o:
								(pch_w_sel == 2'b10) ? int_jp_addr_q[15:8]:
								pch_q;
			end
		S7_0:							//The following phase for interrupt operation
			begin
				t_p_d	=	S7_1;
				if(!hi_priority_int_on && !lo_priority_int_on) begin
					if(	int_in_sp_0 |int_in_sp_1|int_in_sp_2|int_in_sp_3|int_in_sp_4 |
						int_in_ss_0 |int_in_ss_1|int_in_ss_2|int_in_ss_3|int_in_ss_4 ) begin
						int_jp_addr_d	=	(int_in_sp_0) ? INT_VECTOR_0:
											(int_in_sp_1) ? INT_VECTOR_1:
											(int_in_sp_2) ? INT_VECTOR_2:
											(int_in_sp_3) ? INT_VECTOR_3:
											(int_in_sp_4) ? INT_VECTOR_4:
											
											(int_in_ss_0) ? INT_VECTOR_0:
											(int_in_ss_1) ? INT_VECTOR_1:
											(int_in_ss_2) ? INT_VECTOR_2:
											(int_in_ss_3) ? INT_VECTOR_3:
											(int_in_ss_4) ? INT_VECTOR_4:16'h0000;
										/*
											HIGH Priority
													|
													|
													|
											LOW	Priority
										*/
										//Load the INTERRUPT_P0 instruction
						instr_buffer_d	=	INTERRUPT_P0;
						t_p_d			=	S4_0;
					end
				end
				else if(!hi_priority_int_on && lo_priority_int_on) begin
										//The higher interrupt has interruptted the lower interrupt sub-routine
					if(int_in_sp_0 |int_in_sp_1|int_in_sp_2|int_in_sp_3|int_in_sp_4) begin
						int_jp_addr_d	=	(int_in_sp_0) ? INT_VECTOR_0:
										(int_in_sp_1) ? INT_VECTOR_1:
										(int_in_sp_2) ? INT_VECTOR_2:
										(int_in_sp_3) ? INT_VECTOR_3:
										(int_in_sp_4) ? INT_VECTOR_4:16'h0000;
						instr_buffer_d	=	INTERRUPT_P0;
						t_p_d			=	S4_0;
				
					end
				end
			end
		S7_1:
				t_p_d	=	S8_0;
		S8_0:							//The S8 phase is called "the end phase",when an instruction 
										// execution has completely done, then the cpu will turn to 
										//S8 phase.In S8 phase, we can get to work on interrupt operaton
			t_p_d	=	S8_1;
		S8_1:
										//Whether the t_p_q jumps to S1_0 phase,is decided by 
										//the instr_decoder
			t_p_d	=	S1_0;
		default:;
	endcase

end
/*
	if(intr_flag && intr_excu_done) begin
				pch_d	=	8'b00;
				case(intr_code)
					3'd0:
						pcl_d	=	8'h03;
										//INT0_n
					3'd1:
						pcl_d	=	8'h0b;
										//T0
					3'd2:	
						pcl_d	=	8'h13;
										//INT1_n
					3'd3:
						pcl_d	=	8'h1b;
										//T1
					3'd4:
						pcl_d	=	8'h23;
										//UART
					default:
						begin
							pch_d	=	pch_q;
							pcl_d	=	pcl_q;
						end
				endcase
			end
*/
							//ALU Block -- Rv1.001
reg		[3:0]	alu_o_l;
reg		alu_cy_l_w;
reg		[2:0]	alu_o_c6;
reg		alu_cy_c6_w;
reg		alu_o_c7;
always @(*)
	begin
		cy_d 	= 1'b0;
		ov_d 	= 1'b0;
		ac_d 	= 1'b0;
		zo_d	= 1'b0;
		if 		(alu_mode_sel ==	ANDS)
			alu_o = alu_in_0 & alu_in_1;
		else if (alu_mode_sel == 	XOR	)
			alu_o = alu_in_0 ^ alu_in_1;
		else if (alu_mode_sel == 	OR	)
			alu_o = alu_in_0 | alu_in_1;
		else if (alu_mode_sel ==	SUM	) begin
			{alu_cy_l_w,alu_o_l		} =alu_in_0[3:0] +alu_in_1[3:0] +alu_in_cy;
			{alu_cy_c6_w,alu_o_c6	} =alu_in_0[6:4] +alu_in_1[6:4] +alu_cy_l_w;
			{cy_d,alu_o_c7			} =alu_in_0[7] +alu_in_1[7] +alu_cy_c6_w;
			alu_o	={alu_o_c7,alu_o_c6,alu_o_l};
			ac_d	=alu_cy_l_w;
			ov_d	=cy_d	^ alu_cy_c6_w;
			zo_d	=(alu_o == 8'b0);
		end
		else if (alu_mode_sel ==	RL)
			alu_o	={ax_q[6:0],ax_q[7]};
		else if (alu_mode_sel ==	RR)
			alu_o	={ax_q[0],ax_q[7:1]};
		else if (alu_mode_sel ==	CPL)
			alu_o	=~alu_in_0;
		else if (alu_mode_sel ==	SWAP)
			alu_o	={alu_in_0[3:0],alu_in_0[7:4]};
		else
			alu_o = 8'b00;
	end
	
							//User register operation and update the processor statue flag
							//The following are BIT Operation
reg		c_bit;
always @(*)
	begin
		sx_d	=sx_q;
		if(!bit_oper_flag)
			begin
				cy_set		=1'b0;
				ac_set		=1'b0;
				ov_set		=1'b0;
				zo_set		=1'b0;
				pr_set		=1'b0;
				c_bit		=1'b0;
			end
		else 
			begin
				cy_set		=1'b0;
				ac_set		=1'b0;
				ov_set		=1'b0;
				zo_set		=1'b0;
				pr_set		=1'b0;
				sx_d	=sx_q;
				case(bit_sel)
					4'h0:	begin
								cy_set	=	set_or_clr_temp;
								c_bit	=	cy_q;
							end
					4'h1:	begin
								zo_set	=	set_or_clr_temp;
								c_bit	=	zo_q;
							end
					4'h2:	begin
								ov_set	=	set_or_clr_temp;
								c_bit	=	ov_q;
							end
					4'h3:	begin
								pr_set	=	set_or_clr_temp;
								c_bit	=	pr_q;
							end
					4'h4,	
					4'h5,
					4'h6,
					4'h7,	
					
					4'h8,	
					4'h9,	
					4'ha,	
					4'hb:	
						begin 
							sx_d[bit_sel - 4'd4]	=	set_or_clr_temp;
							c_bit	=	sx_q[bit_sel - 4'd4];
						end
					
					default:
						begin
						end
				endcase
			end
	end

assign	set_or_clr_temp	=	(bit_mode_sel == 3'b000) ? set_or_clr:
							(bit_mode_sel == 3'b001) ?~c_bit:
							(bit_mode_sel == 3'b010) ?c_bit & cy_q:
							(bit_mode_sel == 3'b011) ?c_bit | cy_q:
							(bit_mode_sel == 3'b100) ?sx_q[bit_sel - 4'd4]:
							(bit_mode_sel == 3'b101) ?cy_q:
							1'b0;
							
always @(posedge clk) 
	if(!sys_rst_n) begin
		ax_q	<=	8'b0;
		bx_q	<=	8'b0;
		sx_q	<=	8'b0;
	
		pch_q	<=	8'b0;
		pcl_q	<=	8'b0;
		
		zo_q	<=	1'b0;
		cy_q	<=	1'b0;
		ov_q	<=	1'b0;
		ac_q	<=	1'b0;
		pr_q	<=	1'b0;
		f0_q	<=	1'b0;
		
		dptrh_q	<=	8'b0;
		dptrl_q	<=	8'b0;
		pcl_cy	<=	1'b0;
		
		sp_q	<=	8'b0;
		
		mem_addr_q	<=	16'b0;
		
		rs0_q	<=	1'b0;
		rs1_q	<=	1'b0;
		
		multi_cycle_times	<=	2'b00;
	end
	else begin
		if	(t_p_q != S6_1) begin
			mem_addr_q[15:8]	<=	(is_base_pch) ?alu_o:mem_addr_d[15:8];
			mem_addr_q[7:0]		<=	(is_base_pcl) ?alu_o:mem_addr_d[7:0];
		end
		rs0_q	<=	rs0_d;
		rs1_q	<=	rs1_d;
		if(t_p_q == S4_1 || t_p_q	==	S5_1)
			begin
				ax_q	<=	ax_q;
				dptrh_q	<=	dptrh_q;
				dptrl_q	<=	dptrl_q;
				sp_q	<=	sp_q;
				bx_q	<=	bx_q;
				sx_q	<=	sx_q;
				case(reg_tar_ss)
						3'd0:	ax_q	<=	reg_w_d;
						3'd1:	dptrh_q	<=	reg_w_d;
						3'd2:	dptrl_q	<=	reg_w_d;
						3'd3:	sp_q	<=	reg_w_d;
						3'd4:	bx_q	<=	reg_w_d;
						3'd5:	sx_q	<=	reg_w_d;
					default:
						begin
						end
				endcase
			end
		else 
			begin
				ax_q	<=	ax_q;
				dptrh_q	<=	dptrh_q;
				dptrl_q	<=	dptrl_q;
				sp_q	<=	sp_q;
				bx_q	<=	bx_q;
				sx_q	<=	sx_q;
			end	
		pcl_cy	<=	1'b0;
		
		if(			((t_p_q ==S1_0&ready_in)	||t_p_q ==S1_1 )
								|| (((t_p_q ==S2_0 &ready_in) || t_p_q == S2_1) && ~mc_b[2])
								|| (((t_p_q ==S3_0 &ready_in) || t_p_q == S3_1) && ~mc_b[7])
								|| ((t_p_q ==S6_0 || (t_p_q == S6_1&ready_in) ) &&( is_jump_flag && is_jump_active))
								) begin
							//May be JMP istruction will use these...
			pch_q	<=	pch_d;
			pcl_q	<=	pcl_d;
			pcl_cy	<=	(t_p_q ==S1_0 ||t_p_q ==S2_0
									|| t_p_q == S3_0 || t_p_q == S6_0) ?cy_d : pcl_cy;
							//The pcl_cy is a shadow register actually
		end
		if(pro_flag_update && t_p_q == S4_1) begin
							//The updae of arithmetic flag is controlled by pro_flag_update signal
			if(bit_oper_flag)
				begin
					zo_q	<=	zo_set	;
					cy_q	<=	cy_set	;
					ov_q	<=	ov_set	;
					ac_q	<=	ac_d	;
					pr_q	<=	pr_set	;
				end
			else
				begin
					zo_q	<=	zo_d	;
					cy_q	<=	cy_d	;
					ov_q	<=	ov_d	;
					ac_q	<=	ac_d	;
					pr_q	<=	
								(ax_q[0] ^ ax_q[1] ^ax_q[2] ^ax_q[3]
								^ax_q[4] ^ax_q[5] ^ax_q[6] ^ax_q[7]);
				end
		end
		else begin
			zo_q	<=	zo_q;
			cy_q	<=	cy_q;
			ov_q	<=	ov_q;
			ac_q	<=	ac_q;
			pr_q	<=	pr_q;
		end
		/*
			Directly addressing can change the value of SFR(Acc,PSW,B) too		......
		*/
		ac_q	<=	(is_wAcc) 	?	mem_wdata:ac_q;
		bx_q	<=	(is_wB)		?	mem_wdata:bx_q;
		sp_q	<=	(is_wSp)	?	mem_wdata:sp_q;
		dptrh_q	<=	(is_wdptrh)	?	mem_wdata:dptrh_q;
		dptrl_q	<=	(is_wdptrl)	?	mem_wdata:dptrl_q;
		{cy_q,ac_q,f0_q,rs1_q,rs0_q,ov_q,pr_q}
				<=	(is_wPSW)	?	mem_wdata:{cy_q,ac_q,f0_q,rs1_q,rs0_q,ov_q,pr_q};
				
		/*
			CJNE	/JBC 	can change the value of cy_q
		*/
		if(is_jump_flag && t_p_q ==S6_0) begin
			cy_q	<=	
						(instr_buffer_q == (CJNE_A_DIR|CJNE_A_IMM|CJNE_F_R0 |CJNE_F_R1)) ? is_jump_active:
						(instr_buffer_q[7:3] ==CJNE_RN_IMM)? is_jump_active:cy_q;
			end
		
		multi_cycle_times	<=	(t_p_q == S6_1 && is_multi_cycles) ? multi_cycle_times +1'b1:
								(t_p_q == S6_1 && ~is_multi_cycles)? 2'b00:
								multi_cycle_times;
	end

wire	[7:0]		ax_q_ss_01;
assign	ax_q_ss_01	=(ax_comp_o) ?~ax_q +8'd1:ax_q;
assign		alu_in_0	=	(alu_in_0_mux_sel == 3'b000) ?ax_q_ss_01:
							(alu_in_0_mux_sel == 3'b001) ?s2_data_buffer_q:
							(alu_in_0_mux_sel == 3'b010) ?8'd1:
							(alu_in_0_mux_sel == 3'b011) ?8'b1111_1111:
							//Neg One..
							8'd0;
assign		alu_in_1	=	(alu_in_1_mux_sel ==4'b0000) ?pcl_q:
							(alu_in_1_mux_sel ==4'b0001) ?pch_q:
							(alu_in_1_mux_sel ==4'b0010) ?dptrl_q:
							(alu_in_1_mux_sel ==4'b0011) ?dptrh_q:
							(alu_in_1_mux_sel ==4'b0100) ?s2_data_buffer_q:
							(alu_in_1_mux_sel ==4'b0101) ?s3_data_buffer_q:
							(alu_in_1_mux_sel ==4'b0110) ?sp_q:
							(alu_in_1_mux_sel ==4'b0111) ?8'd1:
							(alu_in_1_mux_sel ==4'b1000) ?8'd0:8'b0;
assign		alu_in_cy		=(t_p_q ==S1_1 ||t_p_q ==S2_1
								|| t_p_q == S3_1) ?pcl_cy:
								1'b0
								;
assign		reg_w_d			=	(reg_w_mux_ss ==3'b000) 	? s2_data_buffer_q:
								(reg_w_mux_ss	==3'b001) 	? s3_data_buffer_q:
								(reg_w_mux_ss ==3'b010) 	? alu_o:
							//Clear the content of register
								(reg_w_mux_ss ==3'b011) ? 	8'b0:
							//Not change 
								(reg_w_mux_ss ==3'b100)	? 	ax_q:
								(reg_w_mux_ss ==3'b101) ?	bx_q:
								(reg_w_mux_ss ==3'b110) ?	sx_q:
								8'b0;
assign		mem_wdata_ss	=	(mem_wdata_mux_sel	==4'h0) ?	ax_q:
								(mem_wdata_mux_sel  ==4'h1) ?	s2_data_buffer_q:
								(mem_wdata_mux_sel	==4'h2) ?	s3_data_buffer_q:
								(mem_wdata_mux_sel	==4'h3) ?	pch_q:
								(mem_wdata_mux_sel	==4'h4) ?	pcl_q:
								(mem_wdata_mux_sel	==4'h5) ?	bx_q:
								(mem_wdata_mux_sel	==4'h6)	?	sx_q:
																8'b0
								;
assign		r0_w			=	{7'b0,rs1_q,rs0_q,7'b0};
assign		r1_w			=	r0_w	+	16'd1;
assign		r2_w			=	r0_w	+	16'd2;
assign		r3_w			=	r0_w	+	16'd3;
assign		r4_w			=	r0_w	+	16'd4;
assign		r5_w			=	r0_w	+	16'd5;
assign		r6_w			=	r0_w	+	16'd6;
assign		r7_w			=	r0_w	+	16'd7;
							//The question is where the addr comes from?
							//The Address generate circuit
always @(*) 
	begin
		mem_addr_d	=mem_addr_q;
		case(t_p_q)
			S1_1:
				mem_addr_d	={pch_d,pcl_d};
			S2_0,S2_1:
				mem_addr_d	=	(s2_mem_addr_sel == 4'h0) ?{8'b0,r0_w}:
								(s2_mem_addr_sel == 4'h1) ?{8'b0,r1_w}:
								(s2_mem_addr_sel == 4'h2) ?{8'b0,r2_w}:
								(s2_mem_addr_sel == 4'h3) ?{8'b0,r3_w}:
								(s2_mem_addr_sel == 4'h4) ?{8'b0,r4_w}:
								
								(s2_mem_addr_sel == 4'h5) ?{8'b0,r5_w}:
								(s2_mem_addr_sel == 4'h6) ?{8'b0,r6_w}:
								(s2_mem_addr_sel == 4'h7) ?{8'b0,r7_w}:
								(s2_mem_addr_sel == 4'h8) ?{pch_q,pcl_q}:
							//Fetch the next op_code
								(s2_mem_addr_sel == 4'h9) ?{dptrh_q,dptrl_q}:
							//MOVX A,@DPTR
								(s2_mem_addr_sel == 4'ha) ?{dptrh_q,dptrl_q} +ax_q:
							//MOV A,@A+DPTR
								(s2_mem_addr_sel == 4'hb) ?{pch_q,pcl_q} +ax_q:
							//MOV A,@A+PC
								(s2_mem_addr_sel == 4'hc) ?{8'b0,s2_data_buffer_q}:
								
								(s2_mem_addr_sel == 4'hd) ?{8'h0,sp_q}:
								(s2_mem_addr_sel == 4'he) ?s2_data_buffer_q[7:3] + 16'h20:
							//For normal bit operation
								{8'b0,s2_data_buffer_q[7:3],3'b0}
							//For SFR bit operation
								;
								
								
								
				
			S3_0,S3_1:
				mem_addr_d	=	(s3_mem_addr_sel == 3'b000) ? {8'b0,s2_data_buffer_q}:
								(s3_mem_addr_sel == 3'b001) ? {8'b0,sp_q}:
								(s3_mem_addr_sel == 3'b010) ? {8'b0,s3_data_buffer_q}:
								(s3_mem_addr_sel == 3'b011) ? {8'b0,s2_data_buffer_q[7:3],3'b0}:
								(s3_mem_addr_sel == 3'b100) ? {8'b0,r0_w}:
								(s3_mem_addr_sel == 3'b101) ? {8'b0,r1_w}:
								{pch_q,pcl_q}
								;
							//MOV A,direct

			S6_1:			//Perpare for S6 wirte phase
				mem_addr_d	=	(s6_mem_addr_sel == 4'h0) ?{8'b0,r0_w}:
								(s6_mem_addr_sel == 4'h1) ?{8'b0,r1_w}:
								(s6_mem_addr_sel == 4'h2) ?{8'b0,r2_w}:
								(s6_mem_addr_sel == 4'h3) ?{8'b0,r3_w}:
								(s6_mem_addr_sel == 4'h4) ?{8'b0,r4_w}:
								
								(s6_mem_addr_sel == 4'h5) ?{8'b0,r5_w}:
								(s6_mem_addr_sel == 4'h6) ?{8'b0,r6_w}:
								(s6_mem_addr_sel == 4'h7) ?{8'b0,r7_w}: 
								(s6_mem_addr_sel == 4'h8) ?{8'b0,s2_data_buffer_q}:
								(s6_mem_addr_sel == 4'h9) ?{8'b0,s3_data_buffer_q}:
								(s6_mem_addr_sel == 4'ha) ?{dptrh_q,dptrl_q}:
								(s6_mem_addr_sel == 4'hb) ?{8'b0,sp_q}:
							//For push or pop
								(s6_mem_addr_sel == 4'hd) ?s2_data_buffer_q[7:3] + 16'h20:
								(s6_mem_addr_sel == 4'he) ?{pch_q,pcl_q}:
							//For bit operation
							
								{8'b0,s2_data_buffer_q[7:3],3'b0};
							//For SFR bit operation
			default:
				mem_addr_d	=	{pch_q,pcl_q};
				
		endcase
	end
assign		mem_addr		=	(t_p_q == S6_1|
								(t_p_q == S2_0 && s2_rd_ram_nprg)|
								(t_p_q == S3_0 && s3_rd_ram_nprg)|
								(t_p_q == S2_0 && ~s2_rd_ram_nprg
								&& s2_mem_addr_sel != 4'h8))? mem_addr_d:mem_addr_q;		
							/*
The content of mc_b:
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
wire		p_ssr		=	(!we_n &&psen_n_cologic);	
wire		is_PSW		=	(mem_addr[7:3]	==5'b1101_0)	;
wire		is_Acc		=	(mem_addr[7:3]	==5'b1110_0)	;
wire		is_B		=	(mem_addr[7:3]	==5'b1111_0)	;
wire		is_SP		=	(mem_addr[7:3]	==5'b1000_1)	;
wire		is_dptrh	=	(mem_addr[7:0]	==8'h83	)		;
							//This is because the architecture of this "mc51" is not quite compatible to the original one	:)
wire		is_dptrl	=	(mem_addr[7:0]	==8'h82		)	;
wire		is_SCON		=	(mem_addr[7:3]	==5'b1001_1)	;
wire		is_P1		=	(mem_addr[7:3]	==5'b1001_0)	;
wire		is_TCON		=	(mem_addr[7:3]	==5'b1000_1)	;
wire		is_P0		=	(mem_addr[7:3]	==5'b1000_0)	;
wire		is_P2		=	(mem_addr[7:3]	==5'b1010_0)	;
wire		is_P3		=	(mem_addr[7:3]	==5'b1011_0)	;
wire		is_IE		=	(mem_addr[7:3]	==5'b1010_1)	;
wire		is_IP		=	(mem_addr[7:3]	==5'b1011_1)	;
wire		is_bitE_SFR	=	is_Acc |is_B|is_SP|is_SCON|is_P1|is_TCON|is_P0|
							is_P2|is_P3|is_IE|is_IP;
							//This wire stand for the operation of SFR which aims to distinguish the normal bit operation from sfr bit operation	

assign		is_wAcc	=	p_ssr	&	is_Acc;
assign		is_wB	=	p_ssr	&	is_B;
assign		is_wSp	=	p_ssr	&	is_SP;
assign		is_wdptrh	=p_ssr	&	is_dptrh;
assign		is_wdptrl	=p_ssr	&	is_dptrl;
assign		is_wPSW		=p_ssr	&	is_PSW;
/*
							//Memory mapping circuit,even for SFR
always @(*) begin
	is_wAcc	=1'b0;
	is_wPSW	=1'b0;
	is_wB	=1'b0;
	is_wSp	=1'b0;
	if(!we_n &&psen_n_cologic)
		begin
			is_wAcc	=	(mem_addr[]	==	{8'h00,4'he});
			is_wPSW	=	(mem_addr[]	==	{8'h00,4'});
			is_wB	=	(mem_addr[]	==	{8'h00,});
			
		end
end
*/
always @(*)
if(multi_cycle_times == 2'b00)
	casez(instr_buffer_q)
		{MOV_A_RN,3'bz}:
			mc_b	=	{1'b0,2'b0,4'b0,3'b0,2'b0,4'h0,1'b0,1'b0,4'h0,4'h0,3'b000,3'd0,1'b0,3'b000,1'b0,{1'b0,instr_buffer_q[2:0]},1'b1,1'b0,1'b1};
		MOV_A_DIR:
			mc_b	=	{1'b0,2'b0,4'b0,3'b0,2'b0,4'h0,1'b0,1'b0,4'h0,4'h0,3'b001,3'd0,	1'b0,3'b000,1'b1,4'h8,1'b0,1'b1,1'b1};
			
		MOV_A_F_R0:
			mc_b	=	{1'b0,2'b0,4'b0,3'b0,2'b0,4'h0,1'b0,1'b0,4'h0,4'h0,3'b001,3'd0,	1'b0,3'b000,1'b1,4'h0,1'b1,1'b1,1'b1};
		MOV_A_F_R1:
			mc_b	=	{1'b0,2'b0,4'b0,3'b0,2'b0,4'h0,1'b0,1'b0,4'h0,4'h0,3'b001,3'd0,	1'b0,3'b000,1'b1,4'h1,1'b1,1'b1,1'b1};
		
		{MOV_RN_A,3'bz}:
			mc_b	=	{1'b1,2'b0,4'b0,3'b0,2'b0,4'h0,1'b0,1'b0,4'h0,{1'b0,instr_buffer_q[2:0]},3'b100,3'd0,1'b0,3'b000,1'b0,4'h0,1'b0,1'b0,1'b0};
		MOV_A_IMM:
			mc_b	=	{1'b0,2'b0,4'b0,3'b0,2'b0,4'h0,1'b0,1'b0,4'h0,4'h0,3'b000,3'd0,	1'b0,3'b000,1'b0,4'h8,1'b0,1'b0,1'b1};
		{MOV_DIR_RN,3'bz}:
			mc_b	=	{1'b1,2'b0,4'b0,3'b0,2'b0,4'h0,1'b0,1'b0,4'h1,4'h9,3'b100,3'd0,	1'b0,3'b111,1'b0,{1'b0,instr_buffer_q[2:0]},1'b1,1'b1,1'b1};
		{MOV_RN_DIR,3'bz}:
			mc_b	=	{1'b1,2'b0,4'b0,3'b0,2'b0,4'h0,1'b0,1'b0,4'h2,{1'b0,instr_buffer_q[2:0]},3'b100,3'd0,	1'b0,3'b000,1'b1,4'h8,1'b0,1'b1,1'b1};
		{MOV_RN_IMM,3'bz}:
			mc_b	=	{1'b1,2'b0,4'b0,3'b0,2'b0,4'h0,1'b0,1'b0,4'h1,{1'b0,instr_buffer_q[2:0]},3'b100,3'd0,	1'b0,3'b000,1'b0,4'h8,1'b0,1'b0,1'b1};
		MOV_DIR_A:
			mc_b	=	{1'b1,2'b0,4'b0,3'b0,2'b0,4'h0,1'b0,1'b0,4'h0,4'h8,3'b100,3'd0,	1'b0,3'b000,1'b0,4'h8,1'b0,1'b0,1'b1};
		MOV_DIR1_DIR2:
			mc_b	=	{1'b0,2'b0,4'b0,3'b0,2'b0,4'h0,1'b0,1'b0,4'h0,4'h0,3'b100,3'd0,	1'b1,3'b111,1'b0,4'h8,1'b0,1'b1,1'b1};
		MOV_DIR_F_R0:
			mc_b	=	{1'b0,2'b0,4'b0,3'b0,2'b0,4'h0,1'b0,1'b0,4'h0,4'h0,3'b100,3'd0,	1'b1,3'b111,1'b0,4'h0,1'b1,1'b1,1'b1};
		MOV_DIR_F_R1:
			mc_b	=	{1'b0,2'b0,4'b0,3'b0,2'b0,4'h0,1'b0,1'b0,4'h0,4'h0,3'b100,3'd0,	1'b1,3'b111,1'b0,4'h1,1'b1,1'b1,1'b1};
		MOV_DIR_IMM:
			mc_b	=	{1'b1,2'b0,4'b0,3'b0,2'b0,4'h0,1'b0,1'b0,4'h1,4'h9,3'b100,3'd0,	1'b0,3'b111,1'b0,4'h8,1'b0,1'b1,1'b1};
		MOV_F_R0_A:
			mc_b	=	{1'b1,2'b0,4'b0,3'b0,2'b0,4'h0,1'b0,1'b0,4'h0,4'h9,3'b100,3'd0,	1'b0,3'b000,1'b1,4'h0,1'b1,1'b1,1'b1};
		MOV_F_R1_A:
			mc_b	=	{1'b1,2'b0,4'b0,3'b0,2'b0,4'h0,1'b0,1'b0,4'h0,4'h9,3'b100,3'd0,	1'b0,3'b000,1'b1,4'h1,1'b1,1'b1,1'b1};
		
		MOV_F_R0_DIR:
			mc_b	=	{1'b0,2'b0,4'b0,3'b0,2'b0,4'h0,1'b0,1'b0,4'h0,4'h0,3'b100,3'd0,	1'b1,3'b100,1'b1,4'h8,1'b0,1'b1,1'b1};
		MOV_F_R1_DIR:
			mc_b	=	{1'b0,2'b0,4'b0,3'b0,2'b0,4'h0,1'b0,1'b0,4'h0,4'h0,3'b100,3'd0,	1'b1,3'b101,1'b1,4'h8,1'b0,1'b1,1'b1};
			
		MOV_F_R0_IMM:
			mc_b	=	{1'b0,2'b0,4'b0,3'b0,2'b0,4'h0,1'b0,1'b0,4'h1,4'h9,3'b100,3'd0,	1'b0,3'b100,1'b1,4'h8,1'b0,1'b1,1'b1};
		MOV_F_R1_IMM:
			mc_b	=	{1'b0,2'b0,4'b0,3'b0,2'b0,4'h0,1'b0,1'b0,4'h1,4'h9,3'b100,3'd0,	1'b0,3'b101,1'b1,4'h8,1'b0,1'b1,1'b1};
		MOV_DPTR_IMM:
			mc_b	=	{1'b0,2'b0,4'b0,3'b0,2'b0,4'h0,1'b0,1'b0,4'h1,4'ha,3'b100,3'd0,	1'b0,3'b111,1'b0,4'h8,1'b0,1'b0,1'b1};
		MOVC_A_F_DPTRPA:
			mc_b	=	{1'b0,2'b0,4'b0,3'b0,2'b0,4'h0,1'b0,1'b0,4'h1,4'h9,3'b000,3'd0,	1'b0,3'b111,1'b0,4'ha,1'b0,1'b0,1'b1};
		
		NOP:
			mc_b	=	{1'b0,2'b0,4'b0,3'b0,2'b0,4'h0,1'b0,1'b0,4'h0,4'h0,3'b100,3'd0,	1'b0,3'b000,1'b0,4'h8,1'b0,1'b0,1'b0};
		default:
			mc_b	=	{1'b0,2'b0,4'b0,3'b0,2'b0,4'h0,1'b0,1'b0,4'h0,4'h0,3'b100,3'd0,	1'b0,3'b000,1'b0,4'h8,1'b0,1'b0,1'b0};
	endcase
else if(multi_cycle_times == 2'b01)
	casez(instr_buffer_q)	
		MOV_DIR1_DIR2:
			mc_b	=	{1'b1,2'b0,4'b0,3'b0,2'b0,4'h0,1'b0,1'b0,4'h1,4'h9,3'b100,3'd0,	1'b0,3'b111,1'b0,4'hc,1'b1,1'b0,1'b1};
		MOV_DIR_F_R0,MOV_DIR_F_R1:
			mc_b	=	{1'b1,2'b0,4'b0,3'b0,2'b0,4'h0,1'b0,1'b0,4'h1,4'h9,3'b100,3'd0,	1'b0,3'b111,1'b0,4'hc,1'b1,1'b0,1'b1};
		MOV_F_R0_DIR,MOV_F_R0_DIR:
			mc_b	=	{1'b1,2'b0,4'b0,3'b0,2'b0,4'h0,1'b0,1'b0,4'h1,4'h9,3'b100,3'd0,	1'b0,3'b010,1'b1,4'hc,1'b1,1'b1,1'b1};
		default:
			mc_b	={1'b0,2'b0,4'b0,3'b0,2'b0,4'h0,1'b0,1'b0,4'h0,4'h0,3'b100,3'd0,	1'b0,3'b000,1'b0,4'h8,1'b0,1'b0,1'b0};
	endcase
else begin
	mc_b	=	{1'b0,2'b0,4'b0,3'b0,2'b0,4'h0,1'b0,1'b0,4'h0,4'h0,3'b100,3'd0,	1'b0,3'b000,1'b0,4'h8,1'b0,1'b0,1'b0};
end
							//Decoder and Control unit (CU)
always @(*)
	begin
	s3_mem_addr_sel			=		3'h0;
	s2_mem_addr_sel			=		4'h0;
	s6_mem_addr_sel			=		4'he;
	reg_w_mux_ss			=		3'h8;
	s2_rd_ram_nprg			=		1'b0;
	s3_rd_ram_nprg			=		1'b0;
	mem_wdata_mux_sel		=		mc_b[25:22];
	is_s2_fetch				=		1'b0;
	is_s3_fetch				=		1'b0;
	pro_flag_update			=		1'b0;
	ax_comp_o				=		1'b0;
	
	is_multi_cycles			=		mc_b[11];
	alu_mode_sel			=		SUM;
	reg_tar_ss				=		3'b0;
	
	is_base_pch				=		1'b0;
	is_base_pcl				=		1'b0;
	
	alu_in_0_mux_sel		=		3'b010;
	alu_in_1_mux_sel		=		4'b0000;
	
	is_jump_flag			=		1'b0;
	is_call					=		1'b0;
	is_jump_active			=		1'b0;
	
	pc_jgen_sel				=		2'b00;
	pch_w_sel				=		2'b00;
	pcl_w_sel				=		2'b00;
	
	bit_sel					=		4'b0;
	set_or_clr				=		1'b0;
	bit_mode_sel			=		3'b0;
		/*
			This bit is decoded by the following circuit
		*/
	
		bit_oper_flag			=	(instr_buffer_q	==MOV_C_BIT|instr_buffer_q ==MOV_BIT_C|instr_buffer_q == CLR_C|instr_buffer_q ==CLR_BIT|
									instr_buffer_q	==SETB_C |instr_buffer_q ==SETB_BIT |instr_buffer_q ==ANL_C_BIT| instr_buffer_q ==ANL_C_NBIT |
									instr_buffer_q	==ORL_C_BIT | instr_buffer_q ==ORL_C_NBIT |instr_buffer_q ==CPL_BIT |instr_buffer_q ==CPL_C	)?
									1'b1:	1'b0;
							//|instr_buffer_q	==JB|instr_buffer_q ==JNB|instr_buffer_q ==JC|instr_buffer_q ==JNC |instr_buffer_q ==JBC)?	
		bit_sel					=	mc_b[31:28];
		is_jump_flag			=	(instr_buffer_q	==LJMP | instr_buffer_q ==SJMP |instr_buffer_q ==JMP|instr_buffer_q ==JZ |
									instr_buffer_q ==JNZ| instr_buffer_q ==CJNE_A_DIR|instr_buffer_q ==CJNE_A_IMM|instr_buffer_q ==CJNE_F_R0|
									instr_buffer_q ==CJNE_F_R1 |instr_buffer_q[7:3] ==DJNZ_RN |
									instr_buffer_q == JC |instr_buffer_q ==JNC|instr_buffer_q ==JB|instr_buffer_q ==JBC)?
									1'b1:1'b0;
		is_jump_active			=	(instr_buffer_q	==JZ) ?		ax_q	==8'b0:
									(instr_buffer_q	==JNZ)?		ax_q	!=8'b0:
							//The logic of CJNE is quite complex		
									(instr_buffer_q ==CJNE_A_DIR)?		ax_q	!=s3_data_buffer_q:
									(instr_buffer_q	==CJNE_A_IMM)?		ax_q	!=s2_data_buffer_q:
									(instr_buffer_q[7:3] ==CJNE_RN_IMM
									|instr_buffer_q	==CJNE_F_R0
									|instr_buffer_q	==CJNE_F_R1
									)?	 s2_data_buffer_d != s3_data_buffer_d:	
									(instr_buffer_q	==JC)?	cy_q ==1'b1:
									(instr_buffer_q ==JNC)?	cy_q ==1'b0:
									(instr_buffer_q ==JB | JBC)?	c_bit ==1'b1:
									(instr_buffer_q ==JNB) ?		c_bit ==1'b0:
									1'b0;
							//The CJNE instruction above just need one/two cycle
							//DJNZ_RN	-- >DEC_A/DEC_DIR + JNZ/JZ
							//JBC		-- >JB + CLR
							
							//LCALL		-- >PUSH PC ;PUSH PC; SJMP
							//ACALL		-- >PUSH PC;PUSH PC; LJMP 
							//RET/RETI	-- >POP PC;POP PC
		
		pc_jgen_sel				=	mc_b[33:32];
		pch_w_sel				=	mc_b[31:30];
		pcl_w_sel				=	mc_b[29:28];
		{is_s3_fetch,is_s2_fetch}	=	{mc_b[1],mc_b[0]};
		if(t_p_q == S1_0 || t_p_q ==S1_1) begin
				alu_mode_sel	=	SUM;
				alu_in_0_mux_sel	=(t_p_q == S1_0) ?3'b010	:3'b111;
				alu_in_1_mux_sel	=(t_p_q == S1_0) ?4'b0000	:4'b0001;
			end
		else if(t_p_q == S2_0 || t_p_q ==S2_1) begin
			{s2_mem_addr_sel,s2_rd_ram_nprg}
				=	{mc_b[6:3],mc_b[2]};
				alu_mode_sel	=	SUM;
				//Default ALU operation
				alu_in_0_mux_sel	=(t_p_q == S2_0) ?3'b010	:3'b111;
				alu_in_1_mux_sel	=(t_p_q == S2_0) ?4'b0000	:4'b0001;
			end
		else if(t_p_q == S3_0 || t_p_q == S3_1) begin
			{s3_mem_addr_sel,s3_rd_ram_nprg}
				=	{mc_b[10:8],mc_b[7]};
				alu_mode_sel	=	SUM;
				//Default ALU operation
				alu_in_0_mux_sel	=(t_p_q == S3_0) ?3'b010	:3'b111;
				alu_in_1_mux_sel	=(t_p_q == S3_0) ?4'b0000	:4'b0001;
			end
		else if(t_p_q == S4_0|| t_p_q == S4_1) begin
				reg_tar_ss			=mc_b[14:12];
				reg_w_mux_ss		=mc_b[17:15];
				ax_comp_o			=mc_b[27];
				//bit_oper_flag		=mc_b[26];
				is_base_pch			=mc_b[32];
				is_base_pcl			=mc_b[33];
				alu_in_0_mux_sel	=mc_b[36:34];
				alu_in_1_mux_sel	=mc_b[40:37];
				alu_mode_sel		=mc_b[31:28];
				
				bit_mode_sel		=mc_b[40:37];
				set_or_clr			=mc_b[34];
				bit_sel				=mc_b[31:28];
			end
		else if(t_p_q == S5_0|| t_p_q == S5_1) begin
				reg_w_mux_ss		=	3'b010;
                alu_mode_sel        =   SUM;
                reg_tar_ss          =   3'b0;
                alu_in_0_mux_sel    =   3'b000;
                alu_in_1_mux_sel    =   4'hf;
                ax_comp_o           =   1'b0;
                //  ax  <=  ax+8'b0 and the S5 phase can be removed in the future
		end
		else if(t_p_q == S6_0 || t_p_q == S6_1)
			s6_mem_addr_sel		=	mc_b[21:18];
		/*
		else if(t_p_q == S4_0 || t_p_q == S4_1)
			{reg_w_mux_ss}			
		else if(t_p_q == S5_0 || t_p_q ==S5_1)
		
		else if
		*/
	end	
always @(posedge clk)
	if(!sys_rst_n)
		begin
			lo_priority_int_on	<=	1'b0;
			hi_priority_int_on	<=	1'b0;
		end
	else begin
		hi_priority_int_on	<=	(t_p_q ==S7_0 &&(!hi_priority_int_on))? (int_in_sp_0|int_in_sp_1|int_in_sp_2|int_in_sp_3|int_in_sp_4):
								(t_p_q ==S7_0 && instr_buffer_q ==RETI &&(hi_priority_int_on)) ?1'b0:
								hi_priority_int_on;
		lo_priority_int_on	<=	(t_p_q ==S7_0 &&(!lo_priority_int_on) &&(!hi_priority_int_on))? (int_in_ss_0|int_in_ss_1|
								int_in_ss_2|int_in_ss_3|int_in_ss_4) &(!(int_in_sp_0|int_in_sp_1|int_in_sp_2|int_in_sp_3|int_in_sp_4)):
								(t_p_q ==S7_0 && instr_buffer_q ==RETI && (!hi_priority_int_on)) ?1'b0:
								(t_p_q ==S7_0 && instr_buffer_q ==RETI && (hi_priority_int_on)) ?lo_priority_int_on:
								lo_priority_int_on;
	end

integer			index;
always @(posedge clk)
	if(!sys_rst_n)
		begin
			
			IP		<=	8'b0;
			P0_r	<=	8'b0;
			P1_r	<=	8'b0;
			P2_r	<=	8'b0;
			P3_r	<=	8'b0;

			IE		<=	8'b0;
			SCON	<=	8'b0;
			TCON	<=	8'b0;
			for(index =0;index <128;index = index +1)
				begin
					i_ram[index]	=	8'b0;
					e_ram[index]	=	8'b0;
				end
		end
	else begin
		if		(!we_n && psen_n_cologic)
			begin
				if(mem_addr[15:8] == 8'b0)
					begin
						if(mem_addr[7])
							case(mem_addr[7:0])
								8'hB8:
									IP		<=	mem_wdata;
								8'hB0:
									P3_r	<=	mem_wdata;
								8'hA8:
									IE		<=	mem_wdata;
								8'hA0:
									P2_r	<=	mem_wdata;
								8'h98:
									SCON	<=	mem_wdata;
								8'h90:
									P1_r	<=	mem_wdata;
								8'h88:
									TCON	<=	mem_wdata;
								8'h80:
									P0_r	<=	mem_wdata;
								default:
									begin
										
									end
							endcase
						else
							i_ram[mem_addr[6:0]]	<=	mem_wdata;
					end
				else
					e_ram[mem_addr[6:0]]	<=	mem_wdata;
			end
		end

always @(*)
	if(~rd_n && psen_n_cologic)
		begin
			if(mem_addr[15:8] == 8'b0)
				if(mem_addr[7]) 
					case(mem_addr)
						8'hB8:
							c_mem_rdata	=	IP;
						8'hB0:
							c_mem_rdata	=	P3_r;
						8'hA0:
							c_mem_rdata	=	IE;
						8'hA0:
							c_mem_rdata	=	P2_r;
						8'h98:
							c_mem_rdata	=	SCON;
						8'h90:
							c_mem_rdata	=	P1_r;
						8'h88:
							c_mem_rdata	=	TCON;
						8'h80:
							c_mem_rdata	=	P0_r;
						8'hD0:
							c_mem_rdata	=	{cy_q,ac_q,f0_q,rs1_q,rs0_q,ov_q,1'b0,pr_q};
						8'hE0:
							c_mem_rdata	=	ax_q;
						8'hF0:
							c_mem_rdata	=	bx_q;
						8'h81:
							c_mem_rdata	=	sp_q;
						8'h82:
							c_mem_rdata	=	dptrl_q;
						8'h83:
							c_mem_rdata	=	dptrh_q;
						
						default:
							c_mem_rdata	=	8'b0;
						//If we read the undefined-SFR,then the cpu will return zero
					endcase
				else	
					c_mem_rdata	=	i_ram[mem_addr[6:0]];
			else
				c_mem_rdata		=	e_ram[mem_addr[6:0]];
		
		end
	else
		c_mem_rdata	=	mem_rdata;
endmodule