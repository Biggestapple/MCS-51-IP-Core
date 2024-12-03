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
	input					    clk,
	input					    reset_n,

	output					    mem_we_n,
	output					    mem_rd_n,
	output					    mem_psen_n,
	input					    mem_data_rdy,
	input	[7:0]			    mem_rdata,
	output	[7:0]			    mem_wdata,
	output	[15:0]			    mem_addr,
	
	input					    int_req_n,
	output					    int_ack_n,
	input	[7:0]			    int_so_num,
	output					    int_reti
);

//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
wire		[3:0]			    t_p_d;
wire		[3:0]			    t_p_q;

wire							w_we_n;
wire							w_rd_n;
wire							w_psen_n;
wire							w_data_rdy;
wire		[7:0]				w_mem_wdata;
wire		[7:0]				w_pcl,w_pch;
wire		[7:0]				w_psw;
wire		[7:0]				w_mem_rdata;
wire		[15:0]				w_s2_mem_addr_d,w_s3_mem_addr_d,w_s5_mem_addr_d;
wire		[7:0]				w_s1_instr_buffer;
wire		[7:0]				w_s2_data_buffer;
wire		[7:0]				w_s3_data_buffer;
wire		[1:0]				w_ci_stage;
wire		[`MCODE_WIDTH-1:0]	w_mc_b;	
wire		[3:0]				w_t_p_d,w_t_p_q;
wire		[2:0]				w_alu_in0_sel;
wire		[2:0]				w_alu_in1_sel;

wire		[3:0]				w_s2_mem_addr_sel;
wire		[2:0]				w_s3_mem_addr_sel;
wire		[3:0]				w_s5_mem_addr_sel;
wire		[3:0]				w_mem_wdata_sel;

wire							w_is_s2_update_pc;
wire							w_is_s3_update_pc;

wire		[2:0]				w_s2_fetch_mode_sel;
wire		[2:0]				w_s3_fetch_mode_sel;
wire		[2:0]				w_s5_write_mode_sel;
	
wire							w_is_multi_cycles;
wire		[2:0]				w_reg_tar_sel;
wire		[2:0]				w_reg_sor_sel;
wire		[2:0]				w_pc_reload_mode_sel;
	
wire		[4:0]				w_alu_mode;
wire		[3:0]				w_jp_judg_mode;
wire		[2:0]				w_op_psw_mode;

wire		[7:0]				w_alu_in0;
wire		[7:0]				w_alu_in1;
wire		[7:0]				w_alu_o1_temp;
wire		[7:0]				w_alu_o2_temp;
wire		[7:0]				w_alu_psw_temp;
wire							w_alu_ready;

wire							w_jp_active;
wire		[7:0]				w_sp;
wire		[7:0]				w_dpl;
wire		[7:0]				w_dph;
wire		[7:0]				w_acc;
wire		[7:0]				w_bx;
wire		[7:0]				w_sx_0;
wire		[7:0]				w_sx_1;
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
biu						u_biu(
	.clk									(clk							),
	.reset_n								(reset_n						),
	
	.i_t_p_d								(t_p_d							),
	.i_t_p_q								(t_p_q							),
	
	.i_we_n									(w_we_n							),
	.i_rd_n									(w_rd_n							),
	.i_psen_n								(w_psen_n						),
	.o_data_rdy								(w_data_rdy						),
	.o_mem_rdata							(w_mem_rdata					),
	
	.i_pcl									(w_pcl							),
	.i_pch									(w_pch							),
	.i_mem_wdata							(w_mem_wdata					),
	
	.i_s2_mem_addr_d						(w_s2_mem_addr_d				),
	.i_s3_mem_addr_d						(w_s3_mem_addr_d				),
	.i_s5_mem_addr_d						(w_s5_mem_addr_d				),
	
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
	.i_instr_buffer							(w_s1_instr_buffer				),
	.i_ci_stage								(w_ci_stage						),
	
	.o_mc_b									(w_mc_b							)
);
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
op_decoder				u_op_decoder(
	.clk									(clk							),
	.reset_n								(reset_n						),
	
	.i_mc_b									(w_mc_b							),
	.i_t_p_d								(w_t_p_d						),
	.i_t_p_q								(w_t_p_q						),
	
	.o_alu_in0_sel							(w_alu_in0_sel					),
	.o_alu_in1_sel							(w_alu_in1_sel					),
	.o_s2_mem_addr_sel						(w_s2_mem_addr_sel				),
	.o_s3_mem_addr_sel						(w_s3_mem_addr_sel				),
	.o_s5_mem_addr_sel						(w_s5_mem_addr_sel				),
	.o_mem_wdata_sel						(w_mem_wdata_sel				),
	
	.o_is_s2_update_pc						(w_is_s2_update_pc				),
	.o_is_s3_update_pc						(w_is_s3_update_pc				),
	
	.o_s2_fetch_mode_sel					(w_s2_fetch_mode_sel			),
	.o_s3_fetch_mode_sel					(w_s3_fetch_mode_sel			),
	.o_s5_write_mode_sel					(w_s5_write_mode_sel			),
	
	.o_is_multi_cycles						(w_is_multi_cycles				),
	.o_reg_tar_sel							(w_reg_tar_sel					),
	.o_reg_sor_sel							(w_reg_sor_sel					),
	.o_pc_reload_mode_sel					(w_pc_reload_mode_sel			),
	
	.o_alu_mode								(w_alu_mode						),
	.o_jp_judg_mode							(w_jp_judg_mode					),
	.o_op_psw_mode							(w_op_psw_mode					)

);
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
mc51_cu					u_mc51_cu(
	.clk									(clk							),
	.reset_n								(reset_n						),
	
	.i_is_s2_update_pc						(w_is_s2_update_pc				),
	.i_is_s3_update_pc						(w_is_s3_update_pc				),
	
	.i_s2_fetch_mode_sel					(w_s2_fetch_mode_sel			),
	.i_s3_fetch_mode_sel					(w_s3_fetch_mode_sel			),
	.i_s5_write_mode_sel					(w_s5_write_mode_sel			),
	
	.i_is_multi_cycles						(w_is_multi_cycles				),
	.i_reg_tar_sel							(w_reg_tar_sel					),
	.i_reg_sor_sel							(w_reg_sor_sel					),
	.i_pc_reload_mode_sel					(w_pc_reload_mode_sel			),
	
	.i_alu_o1_temp							(w_alu_o1_temp					),
	.i_alu_o2_temp							(w_alu_o2_temp					),
	.i_alu_psw_temp							(w_alu_psw_temp					),
	.i_alu_ready							(w_alu_ready					),

	.i_jp_active							(w_jp_active					),
	
	.i_s2_mem_addr_d						(w_s2_mem_addr_d				),
	.i_s3_mem_addr_d						(w_s3_mem_addr_d				),
	.i_s5_mem_addr_d						(w_s5_mem_addr_d				),
	
	.i_mem_wdata							(w_mem_wdata					),
	.i_mem_rdata							(w_mem_rdata					),
	
	.o_t_p_d								(w_t_p_d						),
	.o_t_p_q								(w_t_p_q						),
	.o_ci_stage								(w_ci_stage						),

	.o_pcl									(w_pcl							),
	.o_pch									(w_pch							),
	.o_psw									(w_psw							),
	.o_sp									(w_sp							),
	.o_dpl									(w_dpl							),
	.o_dph									(w_dph							),
	.o_acc									(w_acc							),
	.o_bx									(w_bx							),
	.o_sx_0									(w_sx_0							),
	.o_sx_1									(w_sx_1							),
	.o_s2_data_buffer						(w_s2_data_buffer				),
	.o_s3_data_buffer						(w_s3_data_buffer				),
	.o_s1_instr_buffer						(w_s1_instr_buffer				),

	.o_we_n									(w_we_n							),
	.o_rd_n									(w_rd_n							),
	.o_psen_n								(w_psen_n						),
	.i_data_rdy								(w_data_rdy						),

	.i_int_req_n							(int_req_n						),
	.o_int_ack_n							(int_ack_n						),
	.i_int_so_num							(int_so_num						),
	.o_int_reti								(int_reti						)
);
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//

mc8051_alu				u_mc8051_alu(
	.clk									(clk							),
	.reset_n								(reset_n						),
	
	.i_alu_mode								(w_alu_mode						),
	.i_jp_judg_mode							(w_jp_judg_mode					),
	.i_op_psw_mode							(w_op_psw_mode					),
	
	.i_alu_in0								(w_alu_in0						),
	.i_alu_in1								(w_alu_in1_sel					),
	
	.i_s3_data_buffer						(w_s3_data_buffer				),
	.i_s2_data_buffer						(w_s2_data_buffer				),
	
	.i_psw									(w_psw							),

	.i_t_p_d								(w_t_p_d						),
	.i_t_p_q								(w_t_p_q						),
	
	.o_alu_o0_temp							(w_alu_o0_temp					),
	.o_alu_o1_temp							(w_alu_o1_temp					),
	.o_alu_psw_temp							(w_alu_psw_temp					),
	.o_alu_ready							(w_alu_ready					),
	.o_jp_active							(w_jp_active					)
);
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
mc8051_mux				u_mc8051_mux(
	.i_alu_in0_sel							(w_alu_in0_sel					),
	.i_alu_in1_sel							(w_alu_in1_sel					),
	.i_s2_mem_addr_sel						(w_s2_mem_addr_sel				),
	.i_s3_mem_addr_sel						(w_s3_mem_addr_sel				),
	.i_s5_mem_addr_sel						(w_s5_mem_addr_sel				),
	.i_mem_wdata_sel						(w_mem_wdata_sel				),
	
	.i_t_p_q								(w_t_p_q						),
	.i_t_p_d								(w_t_p_d						),
	
	.i_pch									(w_pch							),
	.i_pcl									(w_pcl							),
	
	.i_acc									(w_acc							),
	.i_bx									(w_bx							),
	.i_psw									(w_psw							),
	.i_sp									(w_sp							),
	.i_dpl									(w_dpl							),
	.i_dph									(w_dph							),
	
	.i_s1_instr_buffer						(w_s1_instr_buffer				),
	.i_s2_data_buffer						(w_s2_data_buffer				),
	.i_s3_data_buffer						(w_s3_data_buffer				),
	
	.i_sx_0									(w_sx_0							),
	.i_sx_1									(w_sx_1							),	
	
	.o_alu_in0								(w_alu_in0						),
	.o_alu_in1								(w_alu_in1						),
	
	.o_mem_wdata							(w_mem_wdata					),
	.o_s2_mem_addr_d						(w_s2_mem_addr_d				),
	.o_s3_mem_addr_d						(w_s3_mem_addr_d				),
	.o_s5_mem_addr_d						(w_s5_mem_addr_d				)
);

endmodule