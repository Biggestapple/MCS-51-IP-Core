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
//-----------------------------------------------------------------------------------------------------------
`timescale 				1ns/1ps
`include				"global_param.v"
module	mc8051_mux(
	input		[2:0]		i_alu_in0_sel,
	input		[2:0]		i_alu_in1_sel,
	input		[2:0]		i_alu_incy_sel,
	
	input		[3:0]		i_t_p_q,
	input		[3:0]		i_t_p_d,
	
	input		[7:0]		i_s2_data_buf,
	input		[7:0]		i_s3_data_buf,
	
	input		[7:0]		i_sx_0,
	input		[7:0]		i_sx_1,
	input		[7:0]		i_sx_2,
	input		[7:0]		i_sx_3,
													//These shadow bits stand for pcl_cy,dptrl_cy,pcgl_cy and etc
	input					i_sbit_0,
	input					i_sbit_1,
	input					i_sbit_2,
	input					i_sbit_3,
	
	input		[7:0]		i_pch_q,
	input		[7:0]		i_pcl_q,
	
	
	output		[7:0]		o_alu_in0,
	output		[7:0]		o_alu_in1,
	output					o_alu_in_cy,
	
	input		[3:0]		i_reg_wr_sel,
	output		[7:0]		o_reg_wdata,
	
	input		[3:0]		i_mem_wdata_sel,
	output		[7:0]		o_mem_wdata,
	
	input					i_rs0_q,
	input					i_rs1_q,
	
	input		[3:0]		i_s2_mem_addr_sel,
	input		[2:0]		i_s3_mem_addr_sel,
	input		[3:0]		i_s6_mem_addr_sel,
	
	output		[15:0]		o_s2_mem_addr_d,
	output		[15:0]		o_s3_mem_addr_d,
	output		[15:0]		o_s6_mem_addr_d
);

wire		r0_w			=	{7'b0,i_rs1_q,i_rs0_q,7'b0};
wire		r1_w			=	r0_w	+	16'd1;
wire		r2_w			=	r0_w	+	16'd2;
wire		r3_w			=	r0_w	+	16'd3;
wire		r4_w			=	r0_w	+	16'd4;
wire		r5_w			=	r0_w	+	16'd5;
wire		r6_w			=	r0_w	+	16'd6;
wire		r7_w			=	r0_w	+	16'd7;

assign		o_alu_in0		=	(i_alu_in0_sel == 3'b000) ?	i_s2_data_buf:
								(i_alu_in0_sel == 3'b001) ?	i_sx_0:
								(i_alu_in0_sel == 3'b010) ?	i_sx_1:
								(i_alu_in0_sel == 3'b011) ?	i_sx_2:
								(i_alu_in0_sel == 3'b100) ?	i_sx_3:
								(i_alu_in0_sel == 3'b101) ?	8'b0000_0001:
								(i_alu_in0_sel == 3'b110) ?	8'b1111_1111:8'b0000_0000;
													//Neg One..
assign		o_alu_in1		=	(i_alu_in1_sel ==4'b0000) ?	pcl_q:
								(i_alu_in1_sel ==4'b0001) ?	pch_q:
								(i_alu_in1_sel ==4'b0010) ?	i_s2_data_buf:
								(i_alu_in1_sel ==4'b0011) ?	i_s3_data_buf:
								(i_alu_in1_sel ==4'b0100) ?	i_sx_0:
								(i_alu_in1_sel ==4'b0101) ?	i_sx_1:
								(i_alu_in1_sel ==4'b0110) ?	i_sx_2:
								(i_alu_in1_sel ==4'b0111) ?	i_sx_3:
								(i_alu_in1_sel ==4'b1000) ?	8'b0000_0001:8'b0;
								
assign		o_alu_in_cy		=	(i_alu_incy_sel ==3'b000 ) ? i_sbit_0:
								(i_alu_incy_sel ==3'b001 ) ? i_sbit_1:
								(i_alu_incy_sel ==3'b010 ) ? i_sbit_2:
								(i_alu_incy_sel ==3'b011 ) ? i_sbit_3:
								(i_alu_incy_sel ==3'b100 ) ? 1'b1:1'b0;
								
assign		o_mem_wdata		=	(i_mem_wdata_sel ==4'h0) ?	i_s2_data_buf:
								(i_mem_wdata_sel ==4'h1) ?	i_s3_data_buf:
								(i_mem_wdata_sel ==4'h2) ?	i_pch_q:
								(i_mem_wdata_sel ==4'h3) ?	i_pcl_q:
								(i_mem_wdata_sel ==4'h4) ?	i_sx_0:
								(i_mem_wdata_sel ==4'h5) ?	i_sx_1:
								(i_mem_wdata_sel ==4'h6) ?	i_sx_2:
								(i_mem_wdata_sel ==4'h7) ?	i_sx_3:
								(i_mem_wdata_sel ==4'h8) ?	{i_s3_data_buf[7:4],i_s2_data_buf[3:0]}:
															8'b0;

assign		o_s2_mem_addr_d	=	(i_s2_mem_addr_sel == 4'h0) ?{8'b0,r0_w}:
								(i_s2_mem_addr_sel == 4'h1) ?{8'b0,r1_w}:
								(i_s2_mem_addr_sel == 4'h2) ?{8'b0,r2_w}:
								(i_s2_mem_addr_sel == 4'h3) ?{8'b0,r3_w}:
								(i_s2_mem_addr_sel == 4'h4) ?{8'b0,r4_w}:
								
								(i_s2_mem_addr_sel == 4'h5) ?{8'b0,r5_w}:
								(i_s2_mem_addr_sel == 4'h6) ?{8'b0,r6_w}:
								(i_s2_mem_addr_sel == 4'h7) ?{8'b0,r7_w}:
								
								
								(i_s2_mem_addr_sel == 4'h8) ?{i_pch_q,i_pcl_q}:
							//Fetch the next op_code
								(i_s2_mem_addr_sel == 4'h9) ?{i_s3_data_buf,i_s2_data_buf}:
							//MOVX A,@DPTR
								(i_s2_mem_addr_sel == 4'ha) ?{i_s3_data_buf,i_sx_0} +i_s2_data_buf:
							//MOV A,@A+DPTR
								(i_s2_mem_addr_sel == 4'hb) ?{i_pch_q,i_pcl_q} +i_s2_data_buf:
							//MOV A,@A+PC
								(i_s2_mem_addr_sel == 4'hc) ?{8'b0,i_s2_data_buf}:
								(i_s2_mem_addr_sel == 4'hd) ?i_s2_data_buf[7:3] + 16'h20:
							//For normal bit operation
								(i_s2_mem_addr_sel == 4'he) ?{8'b0,i_s2_data_buf[7:3],3'b000}:
							//For SFR bit operation
								{8'b0,	i_sx_0	};

assign		o_s3_mem_addr_d	=	(i_s3_mem_addr_sel == 3'b000) ? {8'b0,i_s2_data_buf}:
								(i_s3_mem_addr_sel == 3'b001) ? {8'b0,i_s3_data_buf}:
								(i_s3_mem_addr_sel == 3'b010) ? {8'b0,i_s2_data_buf[7:3],3'b000}:
								(i_s3_mem_addr_sel == 3'b011) ? {8'b0,i_sx_0}:
								(i_s3_mem_addr_sel == 3'b100) ? {8'b0,r0_w}:
								(i_s3_mem_addr_sel == 3'b101) ? {8'b0,r1_w}:
								{i_pch_q,i_pcl_q};
							//MOV A,direct

assign		o_s6_mem_addr_d	=	(i_s6_mem_addr_sel == 4'h0) ?{8'b0,r0_w}:
								(i_s6_mem_addr_sel == 4'h1) ?{8'b0,r1_w}:
								(i_s6_mem_addr_sel == 4'h2) ?{8'b0,r2_w}:
								(i_s6_mem_addr_sel == 4'h3) ?{8'b0,r3_w}:
								(i_s6_mem_addr_sel == 4'h4) ?{8'b0,r4_w}:
								
								(i_s6_mem_addr_sel == 4'h5) ?{8'b0,r5_w}:
								(i_s6_mem_addr_sel == 4'h6) ?{8'b0,r6_w}:
								(i_s6_mem_addr_sel == 4'h7) ?{8'b0,r7_w}: 
								
								(i_s6_mem_addr_sel == 4'h8) ?{8'b0,i_s2_data_buf}:
								(i_s6_mem_addr_sel == 4'h9) ?{8'b0,i_s3_data_buf}:
								
								(i_s6_mem_addr_sel == 4'ha) ?{i_s3_data_buf,i_s2_data_buf}:
								(i_s6_mem_addr_sel == 4'hb) ?{8'b0, i_sx_0}:
							//For push or pop
								(i_s6_mem_addr_sel == 4'hd) ?i_s2_data_buf[7:3] + 16'h20:
							//For bit operation
								(i_s6_mem_addr_sel == 4'he) ?{8'b0,	i_sx_1}:
							
							
								{8'b0,i_s2_data_buf[7:3],3'b000};

assign		o_reg_wdata		=	(i_reg_wr_sel == 4'b000) ? 	s2_data_buffer_q:
								(i_reg_wr_sel == 3'b001) ? 	s3_data_buffer_q:
								(i_reg_wr_sel == 3'b010) ? 	alu_o:
							//Clear the content of register
								(i_reg_wr_sel == 3'b011) ?	8'b0:
							//Not change 
								(i_reg_wr_sel == 3'b100) ? 	i_sx_0:
								(i_reg_wr_sel == 3'b101) ?	i_sx_0:
								(i_reg_wr_sel == 3'b110) ?	i_sx_0:
															i_sx_3;
endmodule