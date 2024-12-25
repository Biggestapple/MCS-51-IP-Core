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
module op_decoder(
	input					clk,
	input					reset_n,
	
	input		[43:0]		i_mc_b,
	input		[3:0]		i_t_p_d,
	input		[7:0]		i_s2_data_buf,
	input		[7:0]		i_instr_buf,
	
	output		reg			o_is_s2_fetch,
	output		reg			o_is_s3_fetch,
	
	output		reg			o_s2_rd_ram_nprg,
	output		reg	[3:0]	o_s2_mem_addr_sel,
	
	output		reg			o_s3_rd_ram_nprg,
	output		reg	[2:0]	o_s3_mem_addr_sel,
	
	output		reg	[2:0]	o_reg_tar_sel,
	output		reg	[2:0]	o_reg_wr_sel,
	
	output		reg			o_ax_comp,
	
	output		reg			o_is_base_pch,
	output		reg			o_is_base_pcl,
	
	output		reg	[2:0]	o_alu_in0_sel,
	output		reg	[3:0]	o_alu_in1_sel,
	output		reg	[3:0]	o_alu_mode,
	
	output		reg	[3:0]	o_bit_mode,
	output		reg			o_bit_set_or_clr,
	output		reg	[3:0]	o_bit_sel,
	
	output		reg	[3:0]	o_s6_mem_addr_sel,
	output		reg	[3:0]	o_mem_wdata_sel,
	output		reg			o_pro_flag_update,
	
	output		reg			o_is_wr_ram,
	output		reg			o_is_multi_cycles,
	
	output		reg			o_is_jpf,
	output		reg			o_bit_opf,
	
	output		reg			o_is_jp,
	output		reg			o_is_call,
	
	output		reg	[1:0]	o_pc_jgen_sel,
	output		reg	[1:0]	o_pch_w_sel,
	output		reg	[1:0]	o_pcl_w_sel
);
												/*
	Note:	The instruction decoding flow-->
	
	instr_buffer(8 bit)	-->	mc_decoder_unit --converts to --> mc_b(44 bit) --> op_decoder_unit --converts to -->control signals
												*/
wire			pc_jgen_sel 		=		i_mc_b[33:32];
always @(posedge clk or negedge reset_n)
	if(~reset_n) begin
		o_s3_mem_addr_sel			<=		3'h0;
		o_s2_mem_addr_sel			<=		4'h0;
		o_s6_mem_addr_sel			<=		4'he;
		
		o_reg_wr_sel				<=		3'h8;
		
		o_s2_rd_ram_nprg			<=		1'b0;
		o_s3_rd_ram_nprg			<=		1'b0;
		o_mem_wdata_sel				<=		4'b0;
		
		o_is_s2_fetch				<=		1'b0;
		o_is_s3_fetch				<=		1'b0;
		o_pro_flag_update			<=		1'b0;
		o_ax_comp					<=		1'b0;
		
		o_is_wr_ram					<=		1'b0;
		o_is_multi_cycles			<=		1'b0;
		o_alu_mode					<=		ALU_SUM;
		o_reg_tar_sel				<=		3'b000;
		
		o_is_base_pch				<=		1'b0;
		o_is_base_pcl				<=		1'b0;
		
		o_alu_in0_sel				<=		3'b010;
		o_alu_in1_sel				<=		4'b0000;
		
		o_is_jpf					<=		1'b0;
		o_is_call					<=		1'b0;
		
		o_pc_jgen_sel				<=		2'b00;
		o_pch_w_sel					<=		2'b00;
		o_pcl_w_sel					<=		2'b00;
		
		o_bit_sel					<=		4'h0;
		o_bit_set_or_clr			<=		1'b0;
		o_bit_mode					<=		3'b000;	
		
		o_pro_flag_update			<=		1'b0;
		//o_bit_opf					<=		1'b0;
		
		//o_is_jpf					<=		1'b0;
		o_is_jp						<=		1'b0;
		
		o_is_s3_fetch				<=		1'b0;
		o_is_s2_fetch				<=		1'b0;
		
	end else begin
		o_mem_wdata_sel				<=		i_mc_b[25:22];
		o_is_wr_ram					<=		i_mc_b[43];
		o_is_multi_cycles			<=		i_mc_b[11];
		o_is_jpf					<=		i_mc_b[42];
													//o_is_call					<=		1'b0;
		o_pro_flag_update			<=		i_mc_b[26];
													//|i_instr_buf	==JB|i_instr_buf ==JNB|i_instr_buf ==JC|i_instr_buf ==JNC |i_instr_buf ==JBC)?	
		o_bit_sel					<=		i_mc_b[31:28];
		
		o_pc_jgen_sel				<=		i_mc_b[33:32];
		o_pch_w_sel					<=		i_mc_b[31:30];
		o_pcl_w_sel					<=		i_mc_b[29:28];
	
		if(t_p_d == S1_0 || t_p_d ==S1_1) begin
				o_alu_mode			<=	ALU_SUM;
				o_alu_in0_sel		<=	(t_p_d == S1_0) ?3'b010	:3'b111;
				o_alu_in1_sel		<=	(t_p_d == S1_0) ?4'b0000	:4'b0001;
			end
		else if(t_p_d == S2_0 || t_p_d ==S2_1) begin
			{o_s2_mem_addr_sel,o_s2_rd_ram_nprg}
				<=	{i_mc_b[6:3],i_mc_b[2]};
				o_alu_mode			<=	ALU_SUM;
													//Default ALU operation
				o_alu_in0_sel		<=	(t_p_d == S2_0) ?3'b010	:3'b111;
				o_alu_in1_sel		<=	(t_p_d == S2_0) ?4'b0000	:4'b0001;
			end
		else if(t_p_d == S3_0 || t_p_d == S3_1) begin
			{o_s3_mem_addr_sel,o_s3_rd_ram_nprg}
				<=	{i_mc_b[10:8],i_mc_b[7]};
				o_alu_mode			<=	ALU_SUM;
													//Default ALU operation
				o_alu_in0_sel		<=	(t_p_d == S3_0) ?3'b010	:3'b111;
				o_alu_in1_sel		<=	(t_p_d == S3_0) ?4'b0000	:4'b0001;
			end
		
		else if(t_p_d == S4_0|| t_p_d == S4_1) begin
				o_reg_tar_sel		<=	i_mc_b[14:12];
				o_reg_wr_sel		<=	i_mc_b[17:15];
				ax_comp_o			<=	i_mc_b[27];
			//bit_oper_flag		=i_mc_b[26];
				o_is_base_pch		<=	i_mc_b[32];
				o_is_base_pcl		<=	i_mc_b[33];
				o_alu_in0_sel		<=	i_mc_b[36:34];
				o_alu_in1_sel		<=	i_mc_b[40:37];
				o_alu_mode			<=	i_mc_b[31:28];
				
				o_bit_mode			<=	i_mc_b[40:37];
				o_bit_set_or_clr	<=	i_mc_b[34];
				o_bit_sel			<=	i_mc_b[31:28];
			end
		else if(t_p_d == S5_0|| t_p_d == S5_1) begin
				o_reg_wr_sel		<=	 3'b010;
                o_alu_mode			<=	 ALU_SUM;
                o_reg_tar_sel		<=   3'b000;
                o_alu_in0_sel		<=   3'b000;
                o_alu_in1_sel		<=   4'hf;
                o_ax_comp           <=   1'b0;
													//  ax  <=  ax+8'b0 and the S5 phase can be removed in the future
		end
		else if(t_p_d == S6_0 || t_p_d == S6_1) begin
			o_s6_mem_addr_sel		<=	i_mc_b[21:18];
			if(pc_jgen_sel	== 2'b01) begin
				o_alu_mode			<=	ALU_SUM;
				o_alu_in0_sel		<=	(t_p_d == S6_0) ? 3'b001:{~i_s2_data_buf[7],2'b11};
				o_alu_in1_sel		<=	(t_p_d == S6_0) ? 4'h0:4'h1;
			end
			else if(pc_jgen_sel	== 2'b10) begin
				o_alu_mode			<=	ALU_SUM;
				o_alu_in0_sel		<=	(t_p_d == S6_0) ? 3'b000:3'b111;
				o_alu_in1_sel		<=	(t_p_d == S6_0) ? 4'h2:4'h3;
			
			end
		end
		/*
		else if(t_p_d == S4_0 || t_p_d == S4_1)
			{reg_w_mux_ss}			
		else if(t_p_d == S5_0 || t_p_d ==S5_1)
		
		else if
		*/
	end

always @(posedge clk or negedge reset_n)
	if(~reset_n) begin
		o_bit_opf			<=	1'b0;
		o_is_jpf			<=	1'b0;
		
	end else begin
		o_bit_opf		<=		(i_instr_buf	==MOV_C_BIT|i_instr_buf ==MOV_BIT_C|i_instr_buf == CLR_C|i_instr_buf ==CLR_BIT|
								i_instr_buf	==SETB_C |i_instr_buf ==SETB_BIT |i_instr_buf ==ANL_C_BIT| i_instr_buf ==ANL_C_NBIT |
								i_instr_buf	==ORL_C_BIT | i_instr_buf ==ORL_C_NBIT |i_instr_buf ==CPL_BIT |i_instr_buf ==CPL_C	)?
								1'b1:	1'b0;
							//|i_instr_buf	==JB|i_instr_buf ==JNB|i_instr_buf ==JC|i_instr_buf ==JNC |i_instr_buf ==JBC)?	
		/*
		is_jump_flag			=	(i_instr_buf	==LJMP | i_instr_buf ==SJMP |i_instr_buf ==JMP|i_instr_buf ==JZ |
									i_instr_buf ==JNZ| i_instr_buf ==CJNE_A_DIR|i_instr_buf ==CJNE_A_IMM|i_instr_buf ==CJNE_F_R0|
									i_instr_buf ==CJNE_F_R1 |i_instr_buf[7:3] ==DJNZ_RN |
									i_instr_buf == JC |i_instr_buf ==JNC|i_instr_buf ==JB|i_instr_buf ==JBC|
									i_instr_buf == LCALL|i_instr_buf == RET |i_instr_buf == RETI)?
									1'b1:1'b0;
		*/
		/*
			is_jump_active			<=	(i_instr_buf	==JZ) ?		ax_q	==8'b0:
									(i_instr_buf	==JNZ)?		ax_q	!=8'b0:
							//The logic of CJNE is quite complex		
									(i_instr_buf ==CJNE_A_DIR)?		ax_q	!=s3_data_buffer_q:
									(i_instr_buf	==CJNE_A_IMM)?		ax_q	!=s2_data_buffer_q:
									(i_instr_buf[7:3] ==CJNE_RN_IMM
									||i_instr_buf	==CJNE_F_R0
									||i_instr_buf	==CJNE_F_R1
									)?	 s2_data_buffer_d != s3_data_buffer_d:	
									(i_instr_buf	==JC)?	cy_q ==1'b1:
									(i_instr_buf ==JNC)?	cy_q ==1'b0:
									(i_instr_buf ==JB ||
									 i_instr_buf	==JBC) ?	c_bit ==1'b1:
									(i_instr_buf ==JNB) ?	c_bit ==1'b0:
									1'b1;
		*/
														//The CJNE instruction above just need one/two cycle
							//DJNZ_RN	-- >DEC_A/DEC_DIR + JNZ/JZ
							//JBC		-- >JB + CLR
							
							//LCALL		-- >PUSH PC ;PUSH PC; SJMP
							//ACALL		-- >PUSH PC;PUSH PC; LJMP 
							//RET/RETI	-- >POP PC;POP PC
	end
endmodule