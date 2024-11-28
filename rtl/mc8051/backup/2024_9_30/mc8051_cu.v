//----------------------------------------------------------------------------------------------------------
//	FILE: 		mc8051_cu.v
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
`include				"global_param.v"
module	mc51_cu(
	input					clk,
	input					reset_n,

	input					i_is_s2_fetch,
	input					i_is_s3_fetch,
	input					i_s2_rd_ram_nprg,
	
	input		[3:0]		i_s2_mem_addr_sel,
	input					i_s3_rd_ram_nprg,
	input					i_s2_rd_ram_nprg,
	
	input					i_is_jpf,
	input		[1:0]		i_pch_w_sel,
	input		[1:0]		i_pcl_w_sel,
	
	input		[2:0]		i_reg_tar_sel,
	input		[7:0]		i_reg_wdata,
	
	input					i_is_wr_ram,
	input					i_is_multi_cycles,
	input					i_pro_flag_update,
	
	input					i_bit_opf,
	
	input		[7:0]		i_alu_out,
							//Reuse the ALU dring the address generation
	output		[7:0]		o_pcl,
	output		[7:0]		o_pch,
	
//	output		[7:0]		o_mreg_addr,
//	output		[7:0]		o_mreg_mask,
//	output		[7:0]		o_mreg_tar_sel,
//	output					o_mreg_we,
	
//	output		[15:0]		o_mem_addr,
//	output	reg		[7:0]	o_mem_wdata,

	input		[7:0]		i_mem_rdata,
	output		[3:0]		o_t_p_d,
	output		[3:0]		o_t_p_q,
	
	output					o_we_n,
	output					o_rd_n,
	output					o_psen_n,
	input					i_data_rdy,
	
	input					i_cy,
	input					i_ov,
	input					i_ac,
	input					i_zo,
	
	input					i_zo_set,
	input					i_cy_set,
	input					i_ov_set,
	input					i_pr_set,
	input					i_ac_set,
	input					i_fg_set,
	
	input		[1:0]		i_pc_jgen_sel,
	
	
);
reg		[7:0]	s1_instr_buffer_q;
reg		[7:0]	s1_instr_buffer_d;
reg		[7:0]	s2_data_buffer_q;
reg		[7:0]	s2_data_buffer_d;
reg		[7:0]	s3_data_buffer_q;
reg		[7:0]	s3_data_buffer_d;

							//Shadow register group	#4
reg		[7:0]	sx_0_q;
reg		[7:0]	sx_1_q;
reg		[7:0]	sx_2_q;
reg		[7:0]	sx_3_q;
							//Shadow bit group
reg				pcl_cy;
reg				dptrl_cy;
reg				pcgl_cy;
reg				sbit_3_q;	//General purpose bit

reg				psen_n;
reg				we_n;
reg				rd_n;

reg		[3:0]	t_p_q;
reg		[3:0]	t_p_d;
							//Timing-phase counter
reg		[7:0]	pcl_q;
reg		[7:0]	pcl_d;
reg		[7:0]	pch_q;
reg		[7:0]	pch_d;

//reg		is_two_word;
//wire	is_two_word_d;
//reg		is_three_word;
//wire	is_three_word_d;

reg				is_multi_cycles;
reg		[1:0]	multi_cycle_times;
							//Max instruction cycles --> 4 cycles

wire			is_interrupt_cycle	=	1'b0;
always @(posedge clk or negedge reset_n)
	if(~reset_n)
		t_p_q			<=	S1_0;
	else
		t_p_q			<=	t_p_d;


always @(*) begin
	t_p_d	=	t_p_q;
	pch_d	=	pch_q;
	pcl_d	=	pcl_q;
	
	psen_n	=	1'b1;
	we_n	=	1'b1;
	rd_n	=	1'b1;
	
	pch_d	=	pch_q;
	pcl_d	=	pcl_q;
	
	s1_instr_buffer_d	=	s1_instr_buffer_q;
	s2_data_buffer_d	=	s2_data_buffer_q;
	s3_data_buffer_d	=	s3_data_buffer_q;
	
	case(t_p_q)
		S1_0:				// Beside getting the current instruction 
							// in s1 ~s2 phase,we should generate the next PC value (address)...
			begin
				rd_n		=	1'b0;
				psen_n		=	1'b0;
				
				if(is_interrupt_cycle)
							//Maybe some mistakes here
					t_p_d	=	S4_0;
				else begin
					t_p_d	=	S1_1;
							//Update the lowest 8 bits
					pcl_d	=	i_alu_out;
				end
			end
		S1_1:
			begin
				rd_n		=	1'b0;
				psen_n		=	1'b0;
							//i_data_rdy :H--> instr_buf :vaild --one_clock-->i_is_s2_fetch :vaild
				if(i_data_rdy) begin
					rd_n		=	1'b1;
					psen_n		=	1'b1;
				
					s1_instr_buffer_d	=	i_mem_rdata;
					t_p_d	=	(i_is_s2_fetch) ?S2_0 :
								(i_is_s3_fetch) ?S3_0 : S4_0;
					if(multi_cycle_times ==2'b00) 
						pch_d	=	i_alu_out;
					else
							//When multi_cycle_times !=0 means the mult-cycle instruction has not finished yet,
							//hence the pc value shouldn't add one.
						pch_d	=	pch_q;
					
				end
			end
		S2_0:
			begin
				t_p_d	=	S2_1;
				if(~i_s2_rd_ram_nprg)
					begin
						psen_n	=	1'b0;
						rd_n	=	1'b0;
						pcl_d	=	(i_s2_mem_addr_sel == 4'h8) ?i_alu_out :pcl_q;
							//In this case PC value will add "1" automatically
							//Interesting design...
						
					end
				else begin
						psen_n	=	1'b1;
						rd_n	=	1'b0;
					end
			end
		S2_1:
			begin
				if(i_data_rdy) begin
					rd_n		=	1'b1;
					psen_n		=	1'b1;
					s2_data_buffer_d	=	i_mem_rdata;
					t_p_d	=	(i_is_s3_fetch) ?S3_0:S4_0;
					if(~i_s2_rd_ram_nprg)
						pch_d	=	(i_s2_mem_addr_sel == 4'h8) ?i_alu_out :pch_q;
				end else if(~i_s2_rd_ram_nprg) begin
					psen_n		=	1'b0;
					rd_n		=	1'b0;
				end else begin
					psen_n		=	1'b1;
					rd_n		=	1'b0;
				end
			end
		S3_0:
			begin
				t_p_d	=	S3_1;
				if(~i_s3_rd_ram_nprg)
					begin
						psen_n	=	1'b0;
						rd_n	=	1'b0;
						pcl_d	=	i_alu_out;
					end
				else begin
						psen_n	=	1'b1;
						rd_n	=	1'b0;
					end
			end
		S3_1:
			begin
				if(i_data_rdy) begin
					psen_n	=	1'b1;
					rd_n	=	1'b1;
					t_p_d	=	S4_0;
					s3_data_buffer_d	=	i_mem_rdata;
					if(~i_s3_rd_ram_nprg)
						pch_d	=	alu_o;
				end else if(~i_s3_rd_ram_nprg) begin
					psen_n		=	1'b0;
					rd_n		=	1'b0;
				end else begin
					psen_n		=	1'b1;
					rd_n		=	1'b0;
				end
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
										//The S6 stage is made for jump operation ...
		S6_0:
			begin
				t_p_d	=	S6_1;
				if(i_is_jpf && is_jump_active)
					pcl_d	=	(i_pcl_w_sel == 2'b00) ? pcl_q:
								(i_pcl_w_sel == 2'b01) ? i_alu_out:
								(i_pcl_w_sel == 2'b10) ? int_jp_addr_q[7:0]:
								s3_data_buffer_q;
				
				if(i_is_wr_ram)
					we_n	=	1'b0;
				else
					we_n	=	1'b1;
			end
		S6_1: 
			begin
										//Write the data to ram ... ...
				if(i_data_rdy) begin
					we_n	=	1'b1;
					t_p_d	=	S7_0;
										//We can calculate the target address in one cpu cycle
					if(i_is_jpf && is_jump_active)
						pch_d	=	(i_pch_w_sel == 2'b00) ? pch_q:
									(i_pch_w_sel == 2'b01) ? i_alu_out:
										//How can we caculate the target address without adding any external logic ?
									(i_pch_w_sel == 2'b10) ? int_jp_addr_q[15:8]:
									s2_data_buffer_q;
				end else if(i_is_wr_ram)
					we_n	=	1'b0;
			end
			
		S7_0:
			if(is_multi_cycles)
										//If the instruction needs multi-cycles?
				t_p_d	=	S1_1;
			else
				t_p_d	=	S7_1;
		S7_1:							//The following phase for interrupt operation
			begin
				t_p_d	=	S8_0;
				/*
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
				*/
				/*
											HIGH Priority
													|
													|
													|
											LOW	Priority
				*/
										//Load the INTERRUPT_P0 
				/*
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
				*/
				
			end
		S8_0:							//The S8 phase is called "the end phase",when an instruction 
										// execution has completely done, then the cpu will turn to 
										//S8 phase.In S8 phase, we can get to work on interrupt operaton
			t_p_d	=	S8_1;
		S8_1:
										//Whether the t_p_q jumps to S1_0 phase,is decided by 
										//the instr_decoder
			t_p_d	=	S1_0;
		default:	t_p_d	=	S1_0;
	endcase
			
end

reg			pr_d;
always (*)
			pr_d	=	^sx_0_q;
reg			cy_d;
always (*)
		if(s1_instr_buffer_q	==	RLC_A		)
			cy_d	=	sx_0_q[7];
		else if(s1_instr_buffer_q	==	RRC_A	)
			cy_d	=	sx_0_q[0];
		else
			cy_d	=	i_cy;
										//The following circuit is about the register update
always @(posedge clk or negedge reset_n)
	if(~reset_n) begin
		sx_0_q				<=	'b0;
		sx_1_q				<=	'b0;
		sx_2_q				<=	'b0;
		sx_3_q				<=	'b0;
		
		multi_cycle_times	<=	2'b00;
		
		pcl_cy				<=	1'b0;
//		dptrl_cy			<=	1'b0;
//		pcgl_cy				<=	1'b0;
		sbit_3_q			<=	1'b0;
		
	end else begin
		if(t_p_q == S4_1 || t_p_q	==	S5_1
			&& ~i_is_jpf && ~i_bit_opf)
				case(i_reg_tar_sel)
						3'd0:	sx_0_q	<=	i_reg_wdata;
						3'd1:	sx_1_q	<=	i_reg_wdata;
						3'd2:	sx_2_q	<=	i_reg_wdata;
						3'd3:	sx_3_q	<=	i_reg_wdata;
							//For debugger instruction ...
							//For "XCHD" instruction			
					default:
						begin
						end
				endcase		
		else if(				   (t_p_q	==S1_0	||(t_p_q == S1_1		&i_data_rdy)						)
								|| ((t_p_q 	==S2_0  ||(t_p_q == S2_1		&i_data_rdy)) && ~i_s2_rd_ram_nprg	)
								|| ((t_p_q 	==S3_0 	||(t_p_q == S3_1		&i_data_rdy)) && ~i_s3_rd_ram_nprg	)
								
								|| ((t_p_q 	==S6_0 	|| t_p_q == S6_1) 		&( i_is_jpf && is_jump_active)		)
				) begin
							//May be JMP istruction will use these...
				
				pch_q		<=	pch_d;
				pcl_q		<=	pcl_d;
				
				pcl_cy		<=	(	t_p_q == S1_0 		|| t_p_q ==S2_0
								|| 	t_p_q == S3_0 		|| t_p_q == S6_0) ?i_cy: pcl_cy;
							//The pcl_cy is a shadow register actually
		end else if( t_p_q == S4_1) begin
							//For "bit" operation
			if(i_pro_flag_update	) begin
				sx_3_q		<=	{cy_d,i_ac,sbit_3_q,
							//General purpose bit 
				
								sx_0_q[3:2],i_ov,1'b0,pr_d};
							
			end else if(i_bit_opf	) begin
				sx_3_q		<=	{i_cy_set,i_ac_set,i_fg_set,
				
								sx_0_q[3:2],i_ov_set,1'b0,i_pr_set};
			
			end
			
			
		end
		
	end
							//Special carry control circuit
always @(posedge clk or negedge reset_n)
	if(~reset_n) begin
		dptrl_cy			<=	1'b0;
		pcgl_cy				<=	1'b0;
	end else begin
							/*
								For INC_DPTR
							*/
		dptrl_cy	<=	((t_p_q ==S4_1) 			&& s1_instr_buffer_q		==INC_DPTR			) ? cy_d:
						(multi_cycle_times ==0	 	&& t_p_q == S7_1								) ? 1'b0:dptrl_cy;
		pcgl_cy		<=	((t_p_q ==S6_0) && (i_pc_jgen_sel ==2'b01 || i_pc_jgen_sel ==2'b10)			) ? cy_d:
						(t_p_q ==S6_1																) ? 1'b0:pcgl_cy;
	end

							//Multi cycle flag control circuit
always @(posedge clk or negedge reset_n)
	if(~reset_n)
		multi_cycle_times	<=	'b0;
	else 
		multi_cycle_times	<=	(t_p_q == S7_0 && i_is_multi_cycles		) ? multi_cycle_times +1'b1:
								(t_p_q == S7_0 && ~i_is_multi_cycles	) ? 2'b00:
								multi_cycle_times;

assign		o_pcl			=	pcl_q;
assign		o_pch			=	pch_q;

endmodule