//----------------------------------------------------------------------------------------------------------
//	FILE: 		mc8051_mux.v
// 	AUTHOR:		Biggest_apple
// 	
//	ABSTRACT:
// 	KEYWORDS:	fpga, basic module,signal process
// 
// 	MODIFICATION HISTORY:
//	$Log$
//			Biggest_apple				2024.9.3		Create the file
//			Biggest_apple				2024.11.27		Rebuild All
//          Biggest_apple               2024.12.08      Fixed architecture bugs on xx_F_@Rn_xx instructions
//-----------------------------------------------------------------------------------------------------------
`timescale 				1ns/1ps
`include				"global_param.v"
module	mc8051_mux(
	input		[2:0]		i_alu_in0_sel,
	input		[2:0]		i_alu_in1_sel,
	input		[3:0]		i_s2_mem_addr_sel,
	input		[2:0]		i_s3_mem_addr_sel,
	input		[3:0]		i_s5_mem_addr_sel,
	input		[3:0]		i_mem_wdata_sel,
	
	input		[3:0]		i_t_p_q,
	input		[3:0]		i_t_p_d,
	
	input		[7:0]		i_pch,
	input		[7:0]		i_pcl,
	input		[7:0]		i_acc,
	input		[7:0]		i_bx,
	input		[7:0]		i_psw,
	input		[7:0]		i_sp,
	input		[7:0]		i_dpl,
	input		[7:0]		i_dph,
	input		[7:0]		i_s1_instr_buffer,
	input		[7:0]		i_s2_data_buffer,
	input		[7:0]		i_s3_data_buffer,
	input		[7:0]		i_sx_0,
	input		[7:0]		i_sx_1,	
	
	output		[7:0]		o_alu_in0,
	output		[7:0]		o_alu_in1,
	output		[7:0]		o_mem_wdata,
	output		[15:0]		o_s2_mem_addr_d,
	output		[15:0]		o_s3_mem_addr_d,
	output		[15:0]		o_s5_mem_addr_d
);
wire		[7:0]			r0_w;
assign						r0_w			=	{11'b0,i_psw[4:3],3'b0};
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
assign		o_alu_in0		=	(i_alu_in0_sel			== 	`ALU_I0_ACC		)	?		i_acc									    :
								(i_alu_in0_sel			==	`ALU_I0_S2B		)	?		i_s2_data_buffer						    :
								(i_alu_in0_sel			== 	`ALU_I0_S3B		)	?		i_s3_data_buffer						    :
								(i_alu_in0_sel			==	`ALU_I0_BX		)	?		i_bx									    :   
								(i_alu_in0_sel			==	`ALU_I0_SP		)	?		i_sp									    :
								(i_alu_in0_sel			==	`ALU_I0_DPL		)	?		i_dpl									    :
								(i_alu_in0_sel			==	`ALU_I0_SX0		)	?		i_sx_0									    :		
								(i_alu_in0_sel          ==  `ALU_I0_SX1     )   ?       i_sx_1                                      :
                                8'bzzzz_zzzz;
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
assign		o_alu_in1		=	(i_alu_in1_sel			==	`ALU_I1_S2B	    )	?		i_s2_data_buffer	                        :
								(i_alu_in1_sel			==	`ALU_I1_S3B	    )	?		i_s3_data_buffer	                        :
								(i_alu_in1_sel			==	`ALU_I1_BX		) 	?		i_bx				                        :
								(i_alu_in1_sel			==	`ALU_I1_P1		) 	?		8'h01				                        :
								(i_alu_in1_sel			==	`ALU_I1_N1		) 	?		8'hff				                        :
								(i_alu_in1_sel			==	`ALU_I1_NU		) 	?		8'h00				                        :		
                                8'bzzzz_zzzz;
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
assign		o_s2_mem_addr_d	=	(i_s2_mem_addr_sel  	==	`S2_ADDR_RS0    )	?	{8'b0,r0_w	+	i_s1_instr_buffer[2:0]}		    :
								(i_s2_mem_addr_sel		== 	`S2_ADDR_RS1	)	?	{8'b0,r0_w	+	i_s1_instr_buffer[0]}	        :
								(i_s2_mem_addr_sel		==	`S2_ADDR_PC		) 	?	{i_pch,i_pcl}								    :
							//Fetch the next op_code
								(i_s2_mem_addr_sel		==	`S2_ADDR_INDX16	)	?	{i_s3_data_buffer,i_s2_data_buffer}			    :
								(i_s2_mem_addr_sel		==	`S2_ADDR_INDX8	)	?	{8'b0,i_s2_data_buffer}						    :
								(i_s2_mem_addr_sel		==	`S2_ADDR_SINDX8	)	?	{8'b0,i_s3_data_buffer}						    :
							//MOVX A,@DPTR
								(i_s2_mem_addr_sel		==	`S2_ADDR_DPTR	)	?	{i_dph,i_dpl}								    :
                                (i_s2_mem_addr_sel      ==  `S2_ADDR_DPTRPA )   ?   {i_dph,i_dpl}       +   i_acc                   :					
                            //MOV A,@A+PC
								(i_s2_mem_addr_sel		==	`S2_ADDR_PCPA	)	?	{i_pch,i_pcl}	+	i_acc					    :
								(i_s2_mem_addr_sel		==	`S2_ADDR_BITM0	)	?	i_s2_data_buffer[7:3] + 16'h20				    :
							//For normal bit operation
								(i_s2_mem_addr_sel      ==  `S2_ADDR_BITM1  )   ?   {8'b0,i_s2_data_buffer[7:3],3'b000	}           :
                                8'bzzzz_zzzz;
							//For SFR bit operation
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
assign		o_s3_mem_addr_d	=	(i_s3_mem_addr_sel      ==	`S3_ADDR_RS1    )	?	{8'b0,		r0_w	+	i_s1_instr_buffer[0]}	:
								(i_s3_mem_addr_sel		==	`S3_ADDR_INDX8	)	?	{8'b0,i_s2_data_buffer}							:
								(i_s3_mem_addr_sel		==	`S3_ADDR_BITM0	)	?	i_s2_data_buffer[7:3] + 16'h20				    :
								(i_s3_mem_addr_sel		==	`S3_ADDR_BITM1	)	?	{8'b0,i_s2_data_buffer[7:3],3'b000}				:
								(i_s3_mem_addr_sel		==	`S3_ADDR_SINDX8	)	?	{8'b0,i_s3_data_buffer}							:
								(i_s3_mem_addr_sel		==	`S3_ADDR_PC		)	?	{i_pch,i_pcl}								    :
								(i_s3_mem_addr_sel		==	`S3_ADDR_SX		)	?	{8'b0,i_sx_0}									:
								(i_s3_mem_addr_sel		==	`S3_ADDR_SP		)	?	{8'b0,i_sp}										:
								8'bzzzz_zzzz;
							//MOV A,direct
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
assign		o_s5_mem_addr_d	=	(i_s5_mem_addr_sel		==	`S5_ADDR_RS0    )	?	{8'b0,r0_w	+	i_s1_instr_buffer[2:0]}			:
                                (i_s5_mem_addr_sel		==	`S5_ADDR_RS1    )   ?   {8'b0,		r0_w	+	i_s1_instr_buffer[0]}	:
								(i_s5_mem_addr_sel		==	`S5_ADDR_INDX8	)	?	{8'b0,i_s2_data_buffer}							:
								(i_s5_mem_addr_sel		==	`S5_ADDR_SINDX8	)	?	{8'b0,i_s3_data_buffer}							:			
								(i_s5_mem_addr_sel		==	`S5_ADDR_INDX16	)	?	{i_s3_data_buffer,i_s2_data_buffer}				:
							//For push or pop
								(i_s5_mem_addr_sel		==	`S5_ADDR_BITM0	)	?	i_s2_data_buffer[7:3] + 16'h20					:
								(i_s5_mem_addr_sel		==	`S5_ADDR_BITM1	)	?	{8'b0,i_s2_data_buffer[7:3],3'b000}				:
							//For bit operation
								(i_s5_mem_addr_sel		==	`S5_ADDR_SX		)	?	{8'b0,	i_sx_0		}							:
								(i_s5_mem_addr_sel		==	`S5_ADDR_SP		)	?	{8'b0,	i_sp		}							:
								8'bzzzz_zzzz;
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//							
assign		o_mem_wdata		=	(i_mem_wdata_sel		==	`S5_WR_S2B		)	?	i_s2_data_buffer								:
								(i_mem_wdata_sel		==	`S5_WR_S3B		)	?	i_s3_data_buffer								:
								(i_mem_wdata_sel		==	`S5_WR_ACC		)	?	i_acc											:
								(i_mem_wdata_sel		==	`S5_WR_BX		)	?	i_bx											:
								(i_mem_wdata_sel		==	`S5_WR_SP		)	?	i_sp											:
								(i_mem_wdata_sel		==	`S5_WR_SX0		)	?	i_sx_0											:
								(i_mem_wdata_sel		==	`S5_WR_SX1		)	?	i_sx_1											:
								(i_mem_wdata_sel		==	`S5_WR_PCL		)	?	i_pcl											:
								(i_mem_wdata_sel		==	`S5_WR_PCH		)	?	i_pch											:
								(i_mem_wdata_sel		==	`S5_WR_SPM0		)	?	{i_s3_data_buffer[7:4],i_s2_data_buffer[3:0]}	:
								8'bzzzz_zzzz;
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
endmodule