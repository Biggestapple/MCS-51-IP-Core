//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
//	FILE: 		mc8051_top.v
// 	AUTHOR:		Biggest_apple
// 	
//	ABSTRACT:	
// 	KEYWORDS:	fpga, basic module,signal process
// 
// 	MODIFICATION HISTORY:
//	$Log$
//			Biggest_apple				2024.11.20		Create the project
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
`timescale 				1ns/1ps
`include				"global_param.v"
module mc8051_top(
	input					clk,
	input					reset_n,

	output					mem_we_n,
	output					mem_rd_n,
	output					mem_psen_n,
	input					mem_data_rdy,
	input	[7:0]			mem_rdata,
	output	[7:0]			mem_wdata,
	output	[15:0]			mem_addr,
	
	input					int_req_n,
	output					int_ack_n,
	input	[7:0]			int_so_num,
	output					int_reti
);

//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
wire		[3:0]			t_p_d;
wire		[3:0]			t_p_q;

wire						w_we_n;
wire						w_rd_n;
wire						w_data_rdy;
wire		[7:0]			w_mem_wdata;
wire		[7:0]			w_pcl,w_pch;
wire		[7:0]			w_mem_rdata;
wire		

//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
biu						u_biu(
	.clk									(clk							),
	.reset_n								(reset_n						),
	
	.i_t_p_d								(t_p_d							),
	.i_t_p_q								(t_p_q							),
	
	.i_we_n									(								),
	.i_rd_n									(								),
	.i_psen_n								(								),
	.o_data_rdy								(								),
	.o_mem_rdata							(								),
	
	.i_pcl									(),
	.i_pch									(),
	.i_mem_wdata							(),
	
	.i_s2_mem_addr_d						(),
	.i_s3_mem_addr_d						(								),
	.i_s5_mem_addr_d						(								),
	
	.mem_we_n								(mem_we_n						),
	.mem_rd_n								(mem_rd_n						),
	.mem_psen_n								(mem_psen_n						),
	.mem_data_rdy							(mem_data_rdy					),
	
	.mem_wdata								(mem_wdata						),
	.mem_addr								(mem_addr						),
	.mem_rdata								(mem_rdata						)
);

//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
op_decoder				u_op_decoder(
	.i_instr_buffer							(),
	.i_ci_stage								(),
	
	.o_mc_b									()
);
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
op_decoder				u_op_decoder(
	.clk									(),
	.reset_n								(),
	
	.i_mc_b									(),
	.i_t_p_d								(),
	.i_t_p_q								(),
	
	.o_alu_in0_sel							(),
	.o_alu_in1_sel							(),
	.o_s2_mem_addr_sel						(),
	.o_s3_mem_addr_sel						(),
	.o_s5_mem_addr_sel						(),
	.o_mem_wdata_sel						(),
	
	.o_is_s2_update_pc						(),
	.o_is_s3_update_pc						(),
	
	.o_s2_fetch_mode_sel					(),
	.o_s3_fetch_mode_sel					(),
	.o_s5_write_mode_sel					(),
	
	.o_is_multi_cycles						(),
	.o_reg_tar_sel							(),
	.o_reg_sor_sel							(),
	.o_pc_reload_mode_sel					(),
	
	.o_alu_mode								(),
	.o_jp_judg_mode							(),
	.o_op_psw_mode							()

);
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
mc51_cu					u_mc51_cu(
	.clk									(),
	.reset_n								(),
	
	.i_is_s2_update_pc						(),
	.i_is_s3_update_pc						(),
	
	.i_s2_fetch_mode_sel					(),
	.i_s3_fetch_mode_sel					(),
	.i_s5_write_mode_sel					(),
	
	.i_is_multi_cycles						(),
	.i_reg_tar_sel							(),
	.i_reg_sor_sel							(),
	.i_pc_reload_mode_sel					(),
	
	.i_alu_o1_temp							(),
	.i_alu_o2_temp							(),
	.i_alu_psw_temp							(),
	.i_alu_ready							(),

	.i_jp_active							(),
	
	.i_s2_mem_addr_d						(),
	.i_s3_mem_addr_d						(),
	.i_s5_mem_addr_d						(),
	
	.i_mem_wdata							(),
	.i_mem_rdata							(),
	
	.o_t_p_d								(),
	.o_t_p_q								(),
	.o_ci_stage								(),

	.o_pcl									(),
	.o_pch									(),
	.o_psw									(),
	.o_s2_data_buffer						(),
	.o_s3_data_buffer						(),
	.o_s1_instr_buffer						(),

	.o_we_n									(),
	.o_rd_n									(),
	.o_psen_n								(),
	.i_data_rdy								(),

	.i_int_req_n							(),
	.o_int_ack_n							(),
	.i_int_so_num							(),
	.o_int_reti								()
);

//-----------------------------------------------------------------------------------------------------------------------------------------------------------//

mc8051_alu				u_mc8051_alu(
	.clk									(),
	.reset_n								(),
	
	.i_alu_mode								(),
	.i_jp_judg_mode							(),
	.i_op_psw_mode							(),
	
	.i_alu_in0								(),
	.i_alu_in1								(),
	
	.i_s3_data_buffer						(),
	.i_s2_data_buffer						(),
	
	.i_psw									(),

	.i_t_p_d								(),
	.i_t_p_q								(),
	
	.o_alu_o0_temp							(),
	.o_alu_o1_temp							(),
	.o_alu_psw_temp							(),
	.o_alu_ready							(),
	.o_jp_active							()
);
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
mc8051_mux				u_mc8051_mux(
	.i_alu_in0_sel							(),
	.i_alu_in1_sel							(),
	.i_s2_mem_addr_sel						(),
	.i_s3_mem_addr_sel						(),
	.i_s5_mem_addr_sel						(),
	.i_mem_wdata_sel						(),
	
	.i_t_p_q								(),
	.i_t_p_d								(),
	
	.i_pch									(),
	.i_pcl									(),
	.i_acc									(),
	.i_bx									(),
	.i_psw									(),
	.i_sp									(),
	.i_dpl									(),
	.i_dph									(),
	.i_s1_instr_buffer						(),
	.i_s2_data_buffer						(),
	.i_s3_data_buffer						(),
	.i_sx_0									(),
	.i_sx_1									(),	
	
	.o_alu_in0								(),
	.o_alu_in1								(),
	.o_mem_wdata							(),
	.o_s2_mem_addr_d						(),
	.o_s3_mem_addr_d						(),
	.o_s5_mem_addr_d						()
);

endmodule