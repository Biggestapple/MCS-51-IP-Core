//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
//	FILE: 		mc8051_alu.v
// 	AUTHOR:		Biggest_apple
// 	
//	ABSTRACT:	
// 	KEYWORDS:	fpga, basic module,signal process
// 
// 	MODIFICATION HISTORY:
//	$Log$
//			Biggest_apple				2024.9.3		Create the file
//			Biggest_apple				2024.11.20		Almost rebuild all
//			Biggest_apple				2024.11.24		Continuing ... ...
//			Biggest_apple				2024.11.27		Finished
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
`timescale 				1ns/1ps
`include				"global_param.v"
module mc8051_alu(
	input					clk,
	input					reset_n,
	
	input		[4:0]		i_alu_mode,
	input		[3:0]		i_jp_judg_mode,
	input		[2:0]		i_op_psw_mode,
	
	input		[7:0]		i_alu_in0,
	input		[7:0]		i_alu_in1,
	
	input		[7:0]		i_s3_data_buffer,
	input		[7:0]		i_s2_data_buffer,
	
	input		[7:0]		i_psw,

	input		[3:0]		i_t_p_d,
	input		[3:0]		i_t_p_q,
	
	output		[7:0]		o_alu_o0_temp,
	output		[7:0]		o_alu_o1_temp,
	output		[7:0]		o_alu_psw_temp,
	output					o_alu_ready,
	output					o_jp_active
);
wire			alu_active_d0	=	i_t_p_d == `S4_0    &&  (i_alu_mode != `ALU_RLATCH);
reg				alu_active_d1;
reg				[4:0]		alu_mode;
reg				[7:0]		alu_in0_temp,alu_in1_temp,alu_bin0_temp,alu_bin1_temp;
reg             alu_ready_d0,alu_ready_d1;
wire            alu_ready       =   alu_ready_d1; 
reg				[7:0]       psw_temp;
reg				alu_bfet_bit_q;
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
							//Interesting gramma ... ...
							//Arithmetic operation circuit Current version :2.0.1
always @(posedge clk or negedge reset_n)
	if(~reset_n)			alu_active_d1	<=	1'b0;
	else					alu_active_d1	<=	alu_active_d0;
always @(posedge clk or negedge reset_n)
	if(~reset_n)			alu_mode		<=	`ALU_IDLE_0;
	else if(alu_active_d0)	alu_mode		<=	i_alu_mode;
always @(posedge clk or negedge reset_n)
	if(~reset_n)			alu_bin0_temp	<=	8'bzzzz_zzzz;
	else if(alu_active_d0)	alu_bin0_temp	<=	i_s2_data_buffer;
always @(posedge clk or negedge reset_n)
	if(~reset_n)			alu_bin1_temp	<=	8'bzzzz_zzzz;
	else if(alu_active_d0)	alu_bin1_temp	<=	i_s3_data_buffer;
always @(posedge clk or negedge reset_n)
	if(~reset_n)			alu_in0_temp	<=	8'bzzzz_zzzz;
	else if(alu_active_d0)	alu_in0_temp	<=	i_alu_in0;
always @(posedge clk or negedge reset_n)
	if(~reset_n)			alu_in1_temp	<=	8'bzzzz_zzzz;
	else if(alu_active_d0)	alu_in1_temp	<=	i_alu_in1;
always @(posedge clk or negedge reset_n)
	if(~reset_n)			alu_bfet_bit_q	<=	1'bz;
	else if(alu_active_d0)	alu_bfet_bit_q	<=	i_s3_data_buffer[	i_s2_data_buffer[2:0]	];
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
/*
	NonePipeline_ALU Procession:
		0: If alu_active_d0, Set up register and clear the ready bit	-->	
		1: Calcaluate and put the result to oz_temp, psw_0temp			-->	
		2: Set up psw_1temp, jp_active_temp and set the ready bit		--> To "0"
*/
reg				calc_done_q,calc_done_d;
							//PSW content:{cy,ac,fg,rs[1:0],ov,1'b0(RESERVED),pr};
reg				cy_q,cy_d;
reg				ov_q,ov_d;
reg				ac_q,ac_d;
reg				pr_q,pr_d;

reg				cy_c,ov_c,pr_c,ac_c;
always @(*)
	{cy_c,	ac_c,	ov_c,	pr_c}	=	{i_psw[7:6],	i_psw[2],	i_psw[0]};
							//The flag signals above won't be affected by "i_op_psw_mode"
reg				[7:0]		alu_o0_temp_d,alu_o0_temp_q;
reg				[7:0]		alu_o1_temp_d,alu_o1_temp_q;

always @(posedge clk or negedge reset_n)
	if(~reset_n) begin
		calc_done_q			<=	1'b1;
		cy_q				<=	1'b0;
		ov_q				<=	1'b0;
		ac_q				<=	1'b0;
		pr_q				<=	1'b0;
	end else begin
		calc_done_q			<=	calc_done_d;
		cy_q				<=	cy_d;
		ov_q				<=	ov_d;
		ac_q				<=	ac_d;
		
		pr_q				<=	pr_d;
	end
always @(posedge clk or negedge reset_n)
	if(~reset_n) begin
		alu_o0_temp_q		<=	8'h00;
		alu_o1_temp_q		<=	8'h00;
	end else begin
		alu_o0_temp_q		<=	alu_o0_temp_d;
		alu_o1_temp_q		<=	alu_o1_temp_d;
	end
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
							//Internal wire Defination
/* 
    reg				[3:0]	alu_o_l;
    reg						alu_cy_l_w;
    reg				[2:0]	alu_o_c6;

    reg						alu_cy_c6_w;
    reg						alu_o_c7;
    reg						alu_da_cy_w;
*/
wire			[7:0]	alu_in1_ctemp	=	(~alu_in1_temp) +	1;
reg             [7:0]   alu_in1_atemp;
                                //  Transfer to ==> -in1_temp
reg             [3:0]   alu_add_lbit;
reg             [2:0]   alu_add_hbit;
reg                     alu_add_bit7;

reg                     alu_add_b3cy_w;
reg                     alu_add_b6cy_w;
reg                     alu_add_b7cy_w;
reg                     alu_da_cy_w;

`ifdef	ALU_INCLUDE_MUL
	reg						alu_mul_req;
	reg						alu_mul_rdy;
	
	reg			[15:0]		alu_mul_temp0;
	reg			[15:0]		alu_mul_temp1;
	
	reg			[3:0]		alu_mul_bcnt;
	reg						alu_mul_ov;
	reg			[1:0]		alu_mul_state;
	
	reg						alu_mul_req_d0,	alu_mul_req_d1;
	always @(posedge clk or negedge reset_n)
		if(~reset_n)
			{alu_mul_req_d1,alu_mul_req_d0}			<=		2'b00;
		else
			{alu_mul_req_d1,alu_mul_req_d0}			<=		{alu_mul_req_d0,alu_mul_req};	
	wire	alu_mul_req_pos		=		{alu_mul_req_d1,alu_mul_req_d0}	==	2'b01;
	
	always @(posedge clk or negedge reset_n)
		if(~reset_n) begin
			alu_mul_bcnt		<=	3'd0;
			alu_mul_temp0		<=	16'h00_00;
			alu_mul_temp1		<=	16'h00_00;
			
			alu_mul_ov			<=	1'b0;
			alu_mul_rdy			<=	1'b0;
			alu_mul_state		<=	2'b00;
		end else
			case(alu_mul_state)
				2'b00:
					if(alu_mul_req_pos) begin
							//Reload everything here
							alu_mul_temp0	<=	16'h00_00;
							alu_mul_temp1	<=	{8'h00,		alu_in1_temp};
							
							alu_mul_state	<=	2'b01;
					end else 
						alu_mul_state		<=	2'b00;
							//IDLE_STATE
				2'b01:
					if(alu_mul_bcnt[3]	==	1'b1) begin
						alu_mul_bcnt		<=	4'h0;
						alu_mul_rdy			<=	1'b1;
						alu_mul_state		<=	2'b10;
						
						if(alu_mul_temp0 > 16'h00ff)
							alu_mul_ov		<=	1'b1;
						else
							alu_mul_ov		<=	1'b0;
					end else begin
						alu_mul_temp0		<=	(alu_in0_temp[alu_mul_bcnt])	?	alu_mul_temp1 +	alu_mul_temp0 :alu_mul_temp0;
						alu_mul_temp1		<=	alu_mul_temp1	<<	1;
						alu_mul_bcnt		<=	alu_mul_bcnt +	1'b1;
						alu_mul_state		<=	2'b01;
					end
				2'b10:
					begin
						alu_mul_rdy			<=	1'b0;
						alu_mul_state		<=	2'b00;
					end
				default:
							//Should not jump to here ... ...
						alu_mul_state		<=	2'b00;
			endcase	
`endif
`ifdef	ALU_INCLUDE_DIV
	reg						alu_div_req;
	reg						alu_div_rdy;
	
	reg						alu_div_ov;
	reg			[1:0]		alu_div_state;
	
	reg						alu_div_req_d0,	alu_div_req_d1;
	reg			[7:0]		alu_div_temp0;
	reg			[7:0]		alu_div_temp1;
	reg			[8:0]		alu_div_temp2;
	
	always @(posedge clk or negedge reset_n)
		if(~reset_n)
			{alu_div_req_d1,alu_div_req_d0}			<=		2'b00;
		else
			{alu_div_req_d1,alu_div_req_d0}			<=		{alu_div_req_d0,alu_div_req};
	wire	alu_div_req_pos		=		{alu_div_req_d1,alu_div_req_d0}	==	2'b01;
	
	
	always @(posedge clk or negedge reset_n)
		if(~reset_n) begin
			alu_div_temp0		<=	8'h00;
			alu_div_temp1		<=	8'h00;
			alu_div_temp2		<=	9'h0_00;
			
			alu_div_ov			<=	1'b0;
			alu_div_rdy			<=	1'b0;
			alu_div_state		<=	2'b00;
		end else
			case(alu_div_state)
				2'b00:
					if(alu_div_req_pos) begin
							//Reload everything here
							alu_div_temp0	<=	8'h00;
							alu_div_temp1	<=	8'h00;
							alu_div_temp2	<=	alu_in0_temp;
							
							alu_div_state	<=	2'b01;
					end else 
						alu_div_state		<=	2'b00;
							//IDLE_STATE
				2'b01:
					if(alu_in1_temp	==	8'h00) begin
							//Number divided by zero 
						alu_div_state		<=	2'b10;
						alu_div_rdy			<=	1'b1;
						alu_div_ov			<=	1'b1;
					end else begin
						if(alu_div_temp2	>=	alu_in1_temp) begin
							alu_div_temp2	<=	alu_div_temp2	+	{1'b1,alu_in1_ctemp};
							alu_div_temp0	<=	alu_div_temp0 	+ 	1'b1;
						end else begin
							alu_div_temp1	<=	alu_div_temp2;
							
							alu_div_state	<=	2'b10;
							alu_div_rdy		<=	1'b1;
							alu_div_ov		<=	1'b0;
							
						end
					end
				2'b10:
					begin
						alu_div_rdy			<=	1'b0;
						alu_div_state		<=	2'b00;
					end
					
				default:
						alu_div_state		<=	2'b00;
			endcase
`endif
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
always @(*) begin
	cy_d			=	cy_q;
	ov_d			=	ov_q;
	ac_d			=	ac_q;
	pr_d			=	pr_q;
	calc_done_d		=	1'b0;

	alu_o0_temp_d	=	alu_o0_temp_q;
	alu_o1_temp_d	=	alu_o1_temp_q;
	
	pr_d			=	^alu_in0_temp;
	
	alu_add_lbit    =	'b0;
	alu_add_b3cy_w  =	'b0;
	alu_add_hbit    =	'b0;
	alu_add_b6cy_w  =	'b0;
	alu_add_bit7    =	'b0;
    alu_add_b7cy_w  =   'b0;

	alu_da_cy_w		=	'b0;
    alu_in1_atemp   =   'b0;
	
`ifdef	ALU_INCLUDE_MUL
	alu_mul_req		=	'b0;
`endif
`ifdef	ALU_INCLUDE_DIV
	alu_div_req		=	'b0;
`endif
	
	if(alu_active_d1)
		case(alu_mode)
			`ALU_ARI_ADD,	`ALU_ARI_ADDC,	`ALU_ARI_SUBB:
				begin
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
							//Stupid Stuff Here  ... The subb operation is : result => Atemp = In_0 - In_1 - C_flag
                            //A bit tricky here, but it works
                    alu_in1_atemp                       =	(alu_mode	==	`ALU_ARI_SUBB) ? alu_in1_ctemp : alu_in1_temp;

                    {alu_add_b3cy_w, alu_add_lbit   }	=	alu_in0_temp[3:0]   + ( (alu_mode	==	`ALU_ARI_ADDC)	?	cy_c:1'b0 ) + alu_in1_atemp[3:0]    + ((alu_mode    ==	`ALU_ARI_SUBB)	?	{4{cy_q}}:4'b0  );
                    {alu_add_b6cy_w, alu_add_hbit   }	=	alu_in0_temp[6:4]   + alu_in1_atemp[6:4] + alu_add_b3cy_w                                       + ((alu_mode    ==	`ALU_ARI_SUBB)	?	{3{cy_q}}:3'b0  );
                    {alu_add_b7cy_w, alu_add_bit7   }   =	alu_in0_temp[7]     + alu_in1_atemp[7] + alu_add_b6cy_w                                         + ((alu_mode    ==	`ALU_ARI_SUBB)	?	{1{cy_q}}:1'b0  );
					calc_done_d					        =	1'b1;

                    if(alu_mode    ==   `ALU_ARI_SUBB) begin
                        cy_d                            =   ~alu_add_b7cy_w;
                        ac_d                            =   ~alu_add_b3cy_w;
                        ov_d                            =   cy_d ^ (~alu_add_b7cy_w );
                    end else begin
                        cy_d                            =   alu_add_b7cy_w;
                        ac_d                            =   alu_add_b3cy_w;
                        ov_d                            =   cy_d ^ ( alu_add_b6cy_w );
                    end
				end
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
			`ALU_ARI_RR:
				begin
					alu_o0_temp_d				=	{alu_in0_temp[0]		,alu_in0_temp[7:1]};
					calc_done_d					=	1'b1;
				end
			`ALU_ARI_RL:
				begin
					alu_o0_temp_d				=	{alu_in0_temp[6:0]		,alu_in0_temp[7]};
					calc_done_d					=	1'b1;
				end
			`ALU_ARI_RRC:
				begin
					alu_o0_temp_d				=	{cy_c,					alu_in0_temp[7:1]};
					cy_d						=	alu_in0_temp[0];
					calc_done_d					=	1'b1;
				end
			`ALU_ARI_RLC:
				begin
					alu_o0_temp_d				=	{alu_in0_temp[6:0],				cy_c};
					cy_d						=	alu_in0_temp[7];
					calc_done_d					=	1'b1;
				end
			`ALU_ARI_AND:
				begin
					alu_o0_temp_d	 			=	alu_in0_temp	&	alu_in1_temp;
					calc_done_d					=	1'b1;	
				end
			`ALU_ARI_OR:
				begin
					alu_o0_temp_d	 			=	alu_in0_temp	|	alu_in1_temp;
					calc_done_d					=	1'b1;	
				
				end
			`ALU_ARI_XOR:
				begin
					alu_o0_temp_d	 			=	alu_in0_temp	^	alu_in1_temp;
					calc_done_d					=	1'b1;	
				
				end
			`ALU_ARI_CPL:
				begin
					alu_o0_temp_d	 			=	~alu_in0_temp;
					calc_done_d					=	1'b1;	
				
				end
			`ALU_ARI_SWAP:
				begin
					alu_o0_temp_d				=	{alu_in0_temp[3:0],alu_in0_temp[7:4]};
					calc_done_d					=	1'b1;
				end
			`ALU_ARI_DA:
				begin
							//Note: There are several situations to determine the addition number
					{alu_da_cy_w,alu_o0_temp_d}	=	alu_in0_temp	+	((alu_in0_temp[3:0]	>9 || ac_c	==1'b1) ? 8'h06:8'h00)	+	((alu_in0_temp[7:4]	>9 || cy_c	==1'b1) ? 8'h60:8'h00);
					cy_d						=	(alu_da_cy_w	==	1'b1)	?	1'b1:	cy_q;
					calc_done_d					=	1'b1;
				end
            `ALU_ARI_XCHD:
                begin
                    alu_o0_temp_d               =   {alu_in0_temp[7:4],alu_in1_temp[3:0]};
                    alu_o1_temp_d               =   {alu_in1_temp[7:4],alu_in0_temp[3:0]};
                    calc_done_d                 =   1'b1;
                end
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//			
`ifdef	ALU_INCLUDE_MUL
			`ALU_ARI_MUL:
				begin
					alu_mul_req					=	1'b1;
					
					if(alu_mul_rdy) begin
							alu_o0_temp_d		=	alu_mul_temp0[7:0];
							alu_o1_temp_d		=	alu_mul_temp0[15:8];
							
							ov_d				=	alu_mul_ov;
							cy_d				=	1'b0;
							
							calc_done_d			=	1'b1;
						end
				end
`endif
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
`ifdef	ALU_INCLUDE_DIV
			`ALU_ARI_DIV:
				begin
					alu_div_req					=	1'b1;
					
					if(alu_div_rdy) begin
							alu_o0_temp_d		=	alu_div_temp0;
							alu_o1_temp_d		=	alu_div_temp1;
							
							ov_d				=	alu_div_ov;
							cy_d				=	1'b0;
							
							calc_done_d			=	1'b1;
						end
				end
`endif
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
							//How can I fetch the bit address data ?
			`ALU_LOG_ANLC:
				begin
					calc_done_d			=	1'b1;
				
					cy_d				=	cy_c	&	alu_bfet_bit_q;
				end
			`ALU_LOG_ANLNC:
				begin
					calc_done_d			=	1'b1;
				
					cy_d				=	cy_c	&	~alu_bfet_bit_q;
				end
			`ALU_LOG_CJNE:
				begin
					calc_done_d			=	1'b1;
					
					cy_d				=	(alu_in0_temp	<	alu_in1_temp);
				end
			`ALU_LOG_CLB:
				begin
					alu_o0_temp_d		=	alu_bin1_temp	&	~(8'h01 << alu_bin0_temp[2:0]);
				
					calc_done_d			=	1'b1;
				end
			`ALU_LOG_CLC:
				begin
					cy_d				=	1'b0;
					
					calc_done_d			=	1'b1;
				end
			`ALU_LOG_CPB:
				begin
                    if(alu_bin1_temp[alu_bin0_temp[2:0]])
					    alu_o0_temp_d   =	alu_bin1_temp	&	~(8'h01 << alu_bin0_temp[2:0]   );
                    else
                        alu_o0_temp_d   =   alu_bin1_temp	|	(8'h01 << alu_bin0_temp[2:0]    );
                    calc_done_d         =   1'b1;
				end
			`ALU_LOG_CPC:
				begin
					cy_d				=	~cy_c;
					calc_done_d			=	1'b1;
				end
			`ALU_LOG_MCB:
				begin
                    if(~cy_c)
					    alu_o0_temp_d   =	alu_bin1_temp	&	~(8'h01 << alu_bin0_temp[2:0]   );
                    else
                        alu_o0_temp_d   =   alu_bin1_temp	|	(8'h01 << alu_bin0_temp[2:0]    );
					calc_done_d			=	1'b1;
				end
			`ALU_LOG_MBC:
				begin
					cy_d				=	alu_bfet_bit_q;
					calc_done_d			=	1'b1;
				end
			`ALU_LOG_ORC:
				begin
					calc_done_d			=	1'b1;
					cy_d				=	cy_c	|	alu_bfet_bit_q;
				end
			`ALU_LOG_ORNC:
				begin
					calc_done_d			=	1'b1;
					cy_d				=	cy_c	|	~alu_bfet_bit_q;
					
				end
			`ALU_LOG_STC:
				begin
					calc_done_d			=	1'b1;
					cy_d				=	1'b1;
				end
			`ALU_LOG_STB:
				begin
					calc_done_d			=	1'b1;
					alu_o0_temp_d       =	alu_bin1_temp	|	(8'h01 << alu_bin0_temp[2:0]);
				end
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
			`ALU_INCDPTR:
				begin
					calc_done_d			=	1'b1;
					{alu_o1_temp_d,alu_o0_temp_d}	=	{alu_in1_temp,alu_in0_temp}		+	1'b1;	
				end
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
			`ALU_IDLE_0:
					calc_done_d			=	1'b1;
			default:
				$display ("%m :at time %t Error: Fetched INVALID ALU_MODE in alu_module.", $time);
		endcase
end
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
always @(posedge clk or negedge reset_n)
	if(~reset_n) begin
		alu_ready_d0                    <=	1'b0;
        alu_ready_d1                    <=  1'b0;
		psw_temp						<=	8'bzzzz_zzzz;
	end else begin
		alu_ready_d0				    <=	calc_done_q;
        alu_ready_d1                    <=  alu_ready_d0;
		if(calc_done_q)
			case(i_op_psw_mode)
				`PSW_M0_RELOAD:	psw_temp	<=	i_psw;
				`PSW_M1_RELOAD:	psw_temp	<=	{cy_q,ac_q,i_psw[5:3],ov_q,1'b0,pr_q};
							//PSW content:{cy,ac,fg,rs[1:0],ov,1'b0(RESERVED),pr};
				default begin
					$display ("%m :at time %t Error: Fetched INVALID OP_PSW_MODE in alu_module.", $time);
				end
			endcase
	end
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
reg			jump_active;	//Just Combine-logic here

always @(*)
	begin
		jump_active				=		1'b0;
							//No - jump
		if(i_t_p_d	==	`S6_1)
			case(i_jp_judg_mode)
				`JP_IDLE_0:		jump_active		=	1'b0;
				`JP_NOCOND:		jump_active		=	1'b1;
				`JP_ACCZER:		jump_active		=	alu_in0_temp	==	8'h00;
				`JP_ACCNZE:		jump_active		=	alu_in0_temp	!=	8'h00;
				`JP_CMODE0:		jump_active		=	alu_in0_temp	!=	alu_bin0_temp;
				`JP_CMODE1:		jump_active		=	alu_in0_temp	!=	alu_bin1_temp;
				`JP_CMODE2:		jump_active		=	alu_bin0_temp	!=	alu_bin1_temp;
				`JP_NZMOD0:		jump_active		=	alu_bin0_temp	!=	8'h00;
				`JP_NZMOD1:		jump_active		=	alu_bin1_temp	!=	8'h00;
				`JP_JCMODE:		jump_active		=	cy_c	==	1'b1;
				`JP_JNCMOD:		jump_active		=	cy_c	==	1'b0;
				`JP_JBCMOD:		jump_active		=	alu_bfet_bit_q	==	1'b1;
				`JP_JBNCMD:		jump_active		=	alu_bfet_bit_q	==	1'b0;
				
				default begin
					$display ("%m :at time %t Error: Fetched INVALID JP_JUDG_MODE in alu_module.", $time);
				end
			endcase
	end
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
assign		o_alu_o0_temp						=	alu_o0_temp_q;
assign		o_alu_o1_temp						=	alu_o1_temp_q;
assign		o_alu_psw_temp						=	psw_temp;
assign		o_alu_ready							=	alu_ready;
assign		o_jp_active							=	jump_active;

endmodule