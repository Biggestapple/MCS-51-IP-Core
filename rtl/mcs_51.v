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
reg			[7:0]		mem_wdata;
reg			we_n;
reg			rd_n;
reg			[7:0]		c_mem_rdata;

							//Internal 128 bytes ram and external 128 bytes ram claim
reg			[7:0]		i_ram		[0:127];
reg			[7:0]		e_ram		[0:127];
							//Opcode
localparam	[4:0]		MOV_A_RN	=	5'b1110_1,	MOV_RN_A	=	5'b1111_1,				MOV_DIR_RN	=5'b1000_1;
localparam	[7:0]		MOV_A_DIR	=	8'hE5,MOV_A_F_R0 	=8'hE6,	MOV_A_F_R1 	=8'hE7,		MOV_IMM	 	=8'h74,
						MOV_RN_IMME	=8'h78,		MOV_DIR_A 	=8'hF5,		MOV_DIR1_DIR2=8'h85,
						MOV_DIR_F_R0=	8'h86,MOV_DIR_F_R1	=8'h87,	MOV_DIR_IMM	=8'h75,		MOV_F_R0_A 	=8'hF6,
						MOV_F_R1_A	=	8'hF7,MOV_F_R0_DIR	=8'hA6,	MOV_F_R1_DIR=8'hA7,		MOV_F_R0_IMM=8'h76,
						MOV_F_R1_IMM=	8'h77,MOV_DPTR_IMM	=8'h90,	MOVC_A_F_DPTRPA	=8'h93,	MOVC_A_F_PCPA=8'h83
						
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
reg		[7:0]	dptrh_q;
reg		[7:0]	dptrl_q;
reg		[7:0]	sp_q;
							//Processor statue flag
reg		cy_q;
reg		cy_d;
reg		pcl_cy;
reg		ov_q;
reg		ov_d;


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

reg		[7:0]	instr_buffer;
reg		[7:0]	s2_data_buffer;
reg		[7:0]	instr_buffer_d;
reg		[7:0]	s2_data_buffer_d;
reg		[7:0]	s3_data_buffer;
reg		[7:0]	s3_data_buffer_d;

reg		is_two_word;
wire	is_two_word_d;
reg		is_three_word;
wire	is_three_word_d;

reg		is_double_cycle;
reg		dc_exc_flag;
wire	dc_exc_flag_d;
							//Microcode rom unit
reg		[43:0]		mc_b;	
							//Internal Wire connection

wire	is_interrupt_cycle;
reg		is_base_pch;
reg		is_base_pcl;
reg		is_jump;
reg		is_call;
reg		is_jump_en;
wire	intr_excu_done;
wire	[2:0]	intr_code;
wire			intr_flag;
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


reg		[7:0]	bx_bit_temp;
reg		cy_set;
reg		ac_set;
reg		ov_set;
reg		zo_set;
reg		pr_set;

wire	[7:0]	alu_in_0;
wire	[7:0]	alu_in_1;
reg		[3:0]	alu_mode_sel;	
wire			alu_in_cy;
reg		[2:0]	alu_in_0_mux_sel;
reg		[3:0]	alu_in_1_mux_sel;
							//SFR	register	and 	control
							
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
					RR			=4'h8,
					SWAP		=4'h9;
reg		[7:0]	alu_o;
always @(posedge clk)
	if(!sys_rst_n) begin
		instr_buffer		<=	8'b0;
		s2_data_buffer		<=	8'b0;
		s3_data_buffer		<=	8'b0;

		t_p_q				<=	S1_0;
		mem_wdata			<=	8'b0;
	end
	else begin
		t_p_q			<=t_p_d;
		instr_buffer	<=instr_buffer_d;
		s2_data_buffer	<=s2_data_buffer_d;
		s3_data_buffer	<=s3_data_buffer_d;
		
		mem_wdata		<=(t_p_q == S6_1) ? mem_wdata_ss: mem_wdata;
	end
always @(*) begin	
	t_p_d	=	S1_0;		
	psen_n	=	1'b1;
	we_n	=	1'b1;
	rd_n	=	1'b1;
	pch_d	=	pch_q;
	pcl_d	=	pcl_q;
	
	instr_buffer_d	=	instr_buffer;
	s2_data_buffer_d	=	s2_data_buffer;
	s3_data_buffer_d	=	s3_data_buffer;
	case(t_p_q)
		S1_0:				// Beside getting the current instruction 
							// in s1 ~s2 phase,we should generate the next PC value
			begin
				if(is_interrupt_cycle)
					t_p_d	=	S4_0;
				else begin
					if(dc_exc_flag)
						t_p_d	=	S4_0;
					else
						t_p_d	=	(ready_in) ? S1_1:S1_0;
				
					psen_n	=	1'b0;
					pcl_d	=	alu_o;
				end
			end
		S1_1:
			begin
				t_p_d	=	(is_s2_fetch) ?S2_0 :S4_0;
				psen_n	=	1'b0;
				instr_buffer_d	=	c_mem_rdata;
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
							psen_n	=	1'b0;
							rd_n	=	1'b1;
						end
					3'd1:
						begin
							//Fetch the data from ram
							psen_n	=	1'b1;
							rd_n	=	1'b0;
						end
			
				endcase
		*/
		/*
				t_p_d	=	(ready_in) ? S2_1:S2_0;
		*/
				if(~s2_rd_ram_nprg)
					begin
						psen_n	=	1'b0;
						rd_n	=	1'b1;
						pcl_d	=	alu_o;
					end
				else begin
						psen_n	=	1'b1;
						rd_n	=	1'b0;
				
					end
				t_p_d	=	(ready_in) ? S2_1:S2_0;
			end
		S2_1:
			begin
				if(~s2_rd_ram_nprg) 
					begin
						pch_d	=	alu_o;
						psen_n	=	1'b0;
						rd_n	=	1'b1;
					end
				else begin
						psen_n	=	1'b1;
						rd_n	=	1'b0;
				
					end
				s2_data_buffer_d	=	c_mem_rdata;
				t_p_d	=	(is_s3_fetch) ?S3_0:S4_0;
			end
		
		S3_0:
			begin
				if(~s3_rd_ram_nprg)
					begin
						psen_n	=	1'b0;
						rd_n	=	1'b1;
						pcl_d	=	alu_o;
					end
				else begin
						psen_n	=	1'b1;
						rd_n	=	1'b0;
					end
				t_p_d	=	(ready_in) ? S3_1:S3_0;
			end
		S3_1:
			begin
				if(~s3_rd_ram_nprg) 
					begin
						psen_n	=	1'b0;
						rd_n	=	1'b1;
						pch_d	=	alu_o;
					end
				else begin
						psen_n	=	1'b1;
						rd_n	=	1'b0;
				
					end
				s3_data_buffer_d	=	c_mem_rdata;
				t_p_d	=S4_0;
			end
		S4_0:				
			t_p_d	=	S4_1;
		S4_1:
			t_p_d	=	S5_0;
		S5_0:
			t_p_d	=	S5_1;
		S5_1:
			t_p_d	=	S6_0;
										//Note S4 and S5 phase is used for arithmetic operation
		
		S6_0:
			t_p_d	=	S6_1;
		S6_1:
										//Write the data to ram
			if(mc_b[43]) begin
				t_p_d	=	(ready_in) ? S1_0:S8_1;
				we_n	=	1'b0;
			end
			else
				t_p_d	=	S7_0;
										//The following phase for interrupt operation
		S7_0:
			begin
				t_p_d	=	S7_1;
				if(is_call || is_jump && is_jump_en) begin
					pch_d	=	(pch_w_sel == 2'b00) ? pch_q:
								(pch_w_sel == 2'b01) ? alu_o:
								pch_q;
					pcl_d	=	(pcl_w_sel == 2'b00) ? pcl_q:
								(pcl_w_sel == 2'b01) ? alu_o:
								pcl_q;
				end
			end
		S7_1:
			t_p_d	=	S8_0;
		S8_0:
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
always @*
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
		bx_bit_temp	=bx_q;
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
				bx_bit_temp	=bx_q;
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
							bx_bit_temp[bit_sel - 4'd4]	=	set_or_clr_temp;
							c_bit	=	bx_q[bit_sel - 4'd4];
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
							(bit_mode_sel == 3'b100) ?bx_q[bit_sel - 4'd4]:
							(bit_mode_sel == 3'b101) ?cy_q:
							1'b0;
							
always @(posedge clk) 
	if(!sys_rst_n) begin
		ax_q	<=	8'b0;
		bx_q	<=	8'b0;
	
		pch_q	<=	8'b0;
		pcl_q	<=	8'b0;
		
		zo_q	<=	1'b0;
		cy_q	<=	1'b0;
		ov_q	<=	1'b0;
		ac_q	<=	1'b0;
		pr_q	<=	1'b0;
		
		dptrh_q	<=	8'b0;
		dptrl_q	<=	8'b0;
		pcl_cy	<=	1'b0;
		
		sp_q	<=	8'b0;
		
		mem_addr_q	<=	16'b0;
		dc_exc_flag	<=	1'b0;
		
		rs0_q	<=	1'b0;
		rs1_q	<=	1'b0;
	end
	else begin
		mem_addr_q[15:8]	<=	(is_base_pch) ?alu_o:mem_addr_d[15:8];
		mem_addr_q[7:0]		<=	(is_base_pcl) ?alu_o:mem_addr_d[7:0];
		rs0_q	<=	rs0_d;
		rs1_q	<=	rs1_d;
		if(t_p_q == S4_1 || t_p_q	==	S5_1)
			begin
				ax_q	<=	ax_q;
				dptrh_q	<=	dptrh_q;
				dptrl_q	<=	dptrl_q;
				sp_q	<=	sp_q;
				bx_q	<=	bx_q;
				case(reg_tar_ss)
						3'd0:	ax_q	<=	reg_w_d;
						3'd1:	dptrh_q	<=	reg_w_d;
						3'd2:	dptrl_q	<=	reg_w_d;
						3'd3:	sp_q	<=	reg_w_d;
						3'd4:	bx_q	<=	reg_w_d;
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
			end
							//Only in P4S1 phase the acc register will update
		pcl_cy	<=	1'b0;
		
		dc_exc_flag	<=	dc_exc_flag_d;
		
		if(		t_p_q ==S1_0	||t_p_q ==S1_1 || ((t_p_q ==S2_0 || t_p_q ==S2_1) && mc_b[2])
								|| ((t_p_q ==S3_0 || t_p_q == S3_1) &&
								mc_b[7])) begin
							//May be JMP istruction will use these...
			pch_q	<=	pch_d;
			pcl_q	<=	pcl_d;
			pcl_cy	<=	(t_p_q ==S1_0 ||t_p_q ==S2_0
								|| t_p_q == S3_0) ?cy_d : pcl_cy;
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
	end

wire	[7:0]		ax_q_ss_01;
assign	ax_q_ss_01	=(ax_comp_o) ?~ax_q +8'd1:ax_q;
assign	dc_exc_flag_d	=	(t_p_q == S1_1 && is_double_cycle && ~dc_exc_flag) ? 1'b1:
							(t_p_q	==	S1_0 && dc_exc_flag)? 1'b0:
							dc_exc_flag;
assign		alu_in_0	=	(alu_in_0_mux_sel == 3'b000) ?ax_q_ss_01:
							(alu_in_0_mux_sel == 3'b001) ?s2_data_buffer:
							(alu_in_0_mux_sel == 3'b010) ?8'd1:
							(alu_in_0_mux_sel == 3'b011) ?8'b1111_1111:
							//Neg One..
							8'd0;
assign		alu_in_1	=	(alu_in_1_mux_sel ==4'b0000) ?pcl_q:
							(alu_in_1_mux_sel ==4'b0001) ?pch_q:
							(alu_in_1_mux_sel ==4'b0010) ?dptrl_q:
							(alu_in_1_mux_sel ==4'b0011) ?dptrh_q:
							(alu_in_1_mux_sel ==4'b0100) ?s2_data_buffer:
							(alu_in_1_mux_sel ==4'b0101) ?s3_data_buffer:
							(alu_in_1_mux_sel ==4'b0110) ?sp_q:
							(alu_in_1_mux_sel ==4'b0111) ?8'd1:
							(alu_in_1_mux_sel ==4'b1000) ?8'd0:8'b0;
assign		alu_in_cy		=(t_p_q ==S1_1 ||t_p_q ==S2_1
								|| t_p_q == S3_1) ?pcl_cy:
								1'b0
								;
assign		reg_w_d			=	(reg_w_mux_ss ==3'b000) 	? s2_data_buffer:
								(reg_w_mux_ss	==3'b001) 	? s3_data_buffer:
								(reg_w_mux_ss ==3'b010) 	? alu_o:
							//Clear the content of register
								(reg_w_mux_ss ==3'b011) ? 	8'b0:
							//Not change 
								(reg_w_mux_ss ==3'b100)	? 	ax_q:
								(reg_w_mux_ss ==3'b101) ?	bx_q:
								(reg_w_mux_ss ==3'b110) ?	bx_bit_temp:
								8'b0;
assign		mem_wdata_ss	=	(mem_wdata_mux_sel	==4'h0) ?	ax_q:
								(mem_wdata_mux_sel  ==4'h0) ?	s2_data_buffer:
								(mem_wdata_mux_sel	==4'h1) ?	s3_data_buffer:
								(mem_wdata_mux_sel	==4'h2) ?	pch_q:
								(mem_wdata_mux_sel	==4'h3) ?	pcl_q:
								(mem_wdata_mux_sel	==4'h4) ?	bx_q:
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
			S2_1:
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
								(s2_mem_addr_sel == 4'hc) ?{8'b0,s2_data_buffer}:
								
								(s2_mem_addr_sel == 4'hd) ?{8'h0,sp_q}:
								(s2_mem_addr_sel == 4'he) ?s2_data_buffer[7:3] + 16'h20:
							//For normal bit operation
								{8'b0,s2_data_buffer[7:3],3'b0}
							//For SFR bit operation
								;
								
								
								
				
			S3_1:
				mem_addr_d	=	(s3_mem_addr_sel == 3'b000) ? {8'b0,s2_data_buffer}:
								(s3_mem_addr_sel == 3'b001) ? {8'b0,sp_q}:
								(s3_mem_addr_sel == 3'b010) ? {8'b0,s3_data_buffer}:
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
								(s6_mem_addr_sel == 4'h8) ?{8'b0,s2_data_buffer}:
								(s6_mem_addr_sel == 4'h9) ?{8'b0,s3_data_buffer}:
								(s6_mem_addr_sel == 4'ha) ?{dptrh_q,dptrl_q}:
								(s6_mem_addr_sel == 4'hb) ?{8'b0,sp_q}:
							//For push or pop
								(s6_mem_addr_sel == 4'hd) ?s2_data_buffer[7:3] + 16'h20:
								(s6_mem_addr_sel == 4'he) ?{pch_q,pcl_q}:
							//For bit operation
								16'd0;
			default:
				mem_addr_d	=	mem_addr_q;
				
		endcase
	end
assign		mem_addr		=		mem_addr_q;		
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
	11							This bit indicates whether the instruction needs double cycle
	[14:12]						Target register sel bits that decides which register such as ax,bx and etc will be written new byte in S4 and S5
	[17:15]						These bits decide where the byte come from .."reg_w_mux_ss"
	[21:18]						These bits decide where the mem_wdata's address comes from "s6_mem_addr_sel"
	[25:22]						These bits decide where the mem_wdata comes from	"mem_wdata_mux_sel"
	26							This bit shows if the statue register would be updated in s4_1 phase "bit_oper_flag"
	27							This bit is used for sub related instruction "ax_comp_o"
	
	(alu_mode)					---//	bit_oper_flag	==	1'b0
	
	[31:28]						These bits decide the operation of the alu "alu_mode_sel"
	
	[33:32]						"[is_base_pch,is_base_pcl]" for PC+A ..
	[36:34]						These bits select where the alu's in0 data comes from "alu_in_0_mux_sel"
	[40:37]						These bits select where the alu's in1 data comes from "alu_in_1_mux_sel"
	
	(bit mode)					---//	bit_oper_flag	==	1'b1
	
	[31:28]						These bits decide which register to carry bit operation		"bit_sel"
	34							This bit clears or sets the specific bit		"set_or_clr"								
	[40:38]						These bits decide which bit operation to carry	on "bit_mode_sel"
	
	[42:41]						[is_jump,is_call]	for sub-routine and interrupt service
	43							This bit will decide whether write data to ram
							*/
always @(*)
	begin
		if(instr_buffer[7:3] == MOV_A_RN)
			mc_b	=	44'b0000_0000_0000_0000_0000_0000_0000_0000_00000_0000_101;
		/*
		else if()
			case
				
			endcase
		*/
		else
			mc_b	=	44'b0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
	end
							//Decoder unit
always @(*)
	begin
	s3_mem_addr_sel			=		3'h0;
	s2_mem_addr_sel			=		4'h0;
	s6_mem_addr_sel			=		4'he;
	reg_w_mux_ss			=		3'h8;
	s2_rd_ram_nprg			=		1'b0;
	s3_rd_ram_nprg			=		1'b0;
	mem_wdata_mux_sel		=		4'h0;
	is_s2_fetch				=		1'b0;
	is_s3_fetch				=		1'b0;
	pro_flag_update			=		1'b0;
	ax_comp_o				=		1'b0;
	
	is_double_cycle			=		mc_b[11];
	alu_mode_sel			=		SUM;
	reg_tar_ss				=		3'b0;
	
	is_base_pch				=		1'b0;
	is_base_pcl				=		1'b0;
	
	alu_in_0_mux_sel		=		3'b010;
	alu_in_1_mux_sel		=		4'b0000;
	
	is_jump					=		1'b0;
	is_call					=		1'b0;
	is_jump_en				=		1'b0;
	
	pch_w_sel				=		2'b00;
	pcl_w_sel				=		2'b00;
	
	bit_sel					=		4'b0;
	set_or_clr				=		1'b0;
	bit_mode_sel			=		3'b0;
		/*
			This bit is decoded by the following circuit
		*/
	
		bit_oper_flag			=	(instr_buffer	==)?		1'b1:	1'b0;
		if(t_p_q == S1_0 || t_p_q ==S1_1) begin
				{is_s3_fetch,is_s2_fetch}	=	{mc_b[1],mc_b[0]};
				alu_mode_sel	=	SUM;
				alu_in_0_mux_sel	=(t_p_q == S1_0) ?3'b010	:3'b111;
				alu_in_1_mux_sel	=(t_p_q == S1_0) ?4'b0000	:4'b0001;
			end
		else if(t_p_q == S2_0 || t_p_q ==S2_1) begin
			{s2_mem_addr_sel,s2_rd_ram_nprg}
				=	{mc_b[6:3],mc_b[2]};
				alu_mode_sel	=	SUM;
			end
		else if(t_p_q == S3_0 || t_p_q == S3_1) begin
			{s3_mem_addr_sel,s3_rd_ram_nprg}
				=	{mc_b[10:8],mc_b[7]};
				alu_mode_sel	=	SUM;
			end
		/*
		else if(t_p_q == S4_0 || t_p_q == S4_1)
			{reg_w_mux_ss}			
		else if(t_p_q == S5_0 || t_p_q ==S5_1)
		
		else if
		*/
	end
							//SFR	decoder circuit	not yet...	:)
always @(*)
	begin
		
	
	
	end
						
							//Memory mapping circuit
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
		if		(!we_n)
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
	if(~rd_n)
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