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
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
`timescale 				1ns/1ps
`include				"global_param.v"
module op_decoder(
	input					clk,
	input					reset_n,
	
	input		[`MCODE_WIDTH-1:0]	i_mc_b,
	input		[3:0]		i_t_p_d,
	input		[3:0]		i_t_p_q,
	
	output	reg	[2:0]		o_alu_in0_sel,
	output	reg	[2:0]		o_alu_in1_sel,
	output	reg	[3:0]		o_s2_mem_addr_sel,
	output	reg	[2:0]		o_s3_mem_addr_sel,
	output	reg	[3:0]		o_s5_mem_addr_sel,
	output	reg	[3:0]		o_mem_wdata_sel,
	
	output	reg				o_is_s2_update_pc,
	output	reg				o_is_s3_update_pc,
	
	output	reg	[2:0]		o_s2_fetch_mode_sel,
	output	reg	[2:0]		o_s3_fetch_mode_sel,
	output	reg	[2:0]		o_s5_write_mode_sel,
	
	output	reg				o_is_multi_cycles,
	output	reg	[2:0]		o_reg_tar_sel,
	output	reg	[2:0]		o_reg_sor_sel,
	output	reg	[2:0]		o_pc_reload_mode_sel,
	
	output	reg	[4:0]		o_alu_mode,
	output	reg	[3:0]		o_jp_judg_mode,
	output	reg	[2:0]		o_op_psw_mode

);
always @(posedge clk or negedge reset_n)
	if(~reset_n)
		{o_s2_fetch_mode_sel,o_is_s2_update_pc}		<=	4'h0;
	else
		{o_s2_fetch_mode_sel,o_is_s2_update_pc}		<=	i_mc_b[3:0];
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
always @(posedge clk or negedge reset_n)
	if(~reset_n)
		o_s2_mem_addr_sel							<=	4'h0;
	else
		o_s2_mem_addr_sel							<=	i_mc_b[7:4];
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
always @(posedge clk or negedge reset_n)
	if(~reset_n)
		{o_s3_fetch_mode_sel,o_is_s2_update_pc}		<=	4'h0;
	else
		{o_s3_fetch_mode_sel,o_is_s2_update_pc}		<=	i_mc_b[11:8];
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
always @(posedge clk or negedge reset_n)
	if(~reset_n)
		o_s3_mem_addr_sel							<=	3'b000;
	else
		o_s3_mem_addr_sel							<=	i_mc_b[14:12];
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
always @(posedge clk or negedge reset_n)
	if(~reset_n)
		{o_s5_write_mode_sel,o_mem_wdata_sel}		<=	7'h00;
	else
		{o_s5_write_mode_sel,o_mem_wdata_sel}		<=	i_mc_b[21:15];
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
always @(posedge clk or negedge reset_n)
	if(~reset_n)
		o_s5_mem_addr_sel							<=	4'h0;
	else
		o_s5_mem_addr_sel							<=	i_mc_b[25:22];
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
always @(posedge clk or negedge reset_n)
	if(~reset_n)
		{o_alu_in1_sel,o_alu_in0_sel,o_alu_mode}	<=	11'h000;
	else
		{o_alu_in1_sel,o_alu_in0_sel,o_alu_mode}	<=	i_mc_b[36:26];
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
always @(posedge clk or negedge reset_n)
	if(~reset_n)
		o_op_psw_mode								<=	3'b000;
	else
		o_op_psw_mode								<=	i_mc_b[39:37];
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
always @(posedge clk or negedge reset_n)
	if(~reset_n)
		{o_pc_reload_mode_sel,o_jp_judg_mode}		<=	7'h00;
	else
		{o_pc_reload_mode_sel,o_jp_judg_mode}		<=	i_mc_b[46:40];
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
always @(posedge clk or negedge reset_n)
	if(~reset_n)
		{o_reg_sor_sel,o_reg_tar_sel}				<=	6'h00;
	else
		{o_reg_sor_sel,o_reg_tar_sel}				<=	i_mc_b[62:47];
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
always @(posedge clk or negedge reset_n)
	if(~reset_n)
		o_is_multi_cycles							<=	1'b0;
	else
		o_is_multi_cycles							<=	i_mc_b[63];


endmodule