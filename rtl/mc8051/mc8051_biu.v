//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
//	FILE: 		mc8051_biu.v
// 	AUTHOR:		Biggest_apple
// 	
//	ABSTRACT:	
// 	KEYWORDS:	fpga, basic module,signal process
// 
// 	MODIFICATION HISTORY:
//	$Log$
//			Biggest_apple				2024.9.31		Create the file
//			Biggest_apple				2024.11.29		Rebuild the logic
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
`timescale 				1ns/1ps
`include				"global_param.v"
module biu(
	input					clk,
	input					reset_n,
	
	input		[3:0]		i_t_p_d,
	input		[3:0]		i_t_p_q,
	
	input					i_we_n,
	input					i_rd_n,
	input					i_psen_n,
    input                   i_peri_sfr_req,
	output		reg			o_data_rdy,
	output	reg	[7:0]		o_mem_rdata,
	
	input		[7:0]		i_pcl,
	input		[7:0]		i_pch,
	input		[7:0]		i_mem_wdata,
	
	input		[15:0]		i_s2_mem_addr_d,
	input		[15:0]		i_s3_mem_addr_d,
	input		[15:0]		i_s5_mem_addr_d,
	
	
//Naive-Memory Interface
    output      reg         mem_sfr_n,
	output		reg			mem_we_n,
	output		reg			mem_rd_n,
	output		reg			mem_psen_n,
	input					mem_data_rdy,
	
	output	reg	[7:0]		mem_wdata,
	output	reg	[15:0]		mem_addr,
	input		[7:0]		mem_rdata
);
always @(posedge clk or negedge reset_n)
	if(~reset_n)
		mem_addr			<=	16'h00_00;
	else begin
		if		(i_t_p_q	==	`S1_0   ||  i_t_p_d	==`S1_0 )
			mem_addr		<=	{i_pch,	i_pcl};
		else if	(i_t_p_q	==	`S2_0	||  i_t_p_d ==`S2_0 )
			mem_addr		<=	i_s2_mem_addr_d;
		else if	(i_t_p_q	==	`S3_0	||  i_t_p_d ==`S3_0 )
			mem_addr		<=	i_s3_mem_addr_d;
		else if	(i_t_p_q	==	`S5_0	||  i_t_p_d	==`S5_0 )
			mem_addr		<=	i_s5_mem_addr_d;
		else
			mem_addr		<=	mem_addr;
	end
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
always @(posedge clk or negedge reset_n)
	if(~reset_n)
		mem_wdata			<=	8'bzzzz_zzzz;
	else if(i_t_p_d	==	`S5_0	)
		mem_wdata			<=	i_mem_wdata;
	else
		mem_wdata			<=	mem_wdata;
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
always @(*) begin
        mem_sfr_n           =   ~i_peri_sfr_req;
		mem_we_n			=	i_we_n;
		mem_rd_n			=	i_rd_n;
		mem_psen_n			=	i_psen_n;
		o_data_rdy			=	mem_data_rdy;
		o_mem_rdata			=	mem_rdata;
end

endmodule