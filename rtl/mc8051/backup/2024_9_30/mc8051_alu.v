//----------------------------------------------------------------------------------------------------------
//	FILE: 		mc8051_alu.v
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
module mc8051_alu(
	input					i_alu_oe,

	input		[3:0]		i_alu_mode,
	input		[7:0]		i_alu_in0,
	input		[7:0]		i_alu_in1,
	
	output	reg	[7:0]		o_alu_out,
	
	output	reg				o_cy,
	output	reg				o_ov,
	output	reg				o_ac,
	output	reg				o_zo,
	
	output	reg				o_zo_set,
	output	reg				o_cy_set,
	output	reg				o_ov_set,
	output	reg				o_pr_set,
	output	reg				o_ac_set,
	output	reg				o_fg_set,
	
	input		[3:0]		i_bit_sel,
	input		[2:0]		i_bit_mode,
	input					i_bit_set_or_clr,
	
	
);
							//ALU Block -- Rv1.04.1
							//Arithmetic operation circuit
reg		[3:0]	alu_o_l;
reg		alu_cy_l_w;
reg		[2:0]	alu_o_c6;
reg		alu_cy_c6_w;
reg		alu_o_c7;
wire	[7:0]		alu_in1;
assign				alu_in1	=(i_alu_mode == ALU_SUB)	?	~i_alu_in1 +8'b0000_0001:
															i_alu_in1;
always @(*)
	if(i_alu_oe) begin
			o_cy 	= 1'b0;
			o_ov 	= 1'b0;
			o_ac 	= 1'b0;
			o_zo	= 1'b0;
			if 		(i_alu_mode ==	ALU_ANDS)
				o_alu_out = i_alu_in0 & alu_in1;
			else if (i_alu_mode == 	ALU_XOR	)
				o_alu_out = i_alu_in0 ^ alu_in1;
			else if (i_alu_mode == 	ALU_OR	)
				o_alu_out = i_alu_in0 | alu_in1;
			else if (i_alu_mode ==	ALU_SUM	
					||i_alu_mode == ALU_SUB) begin
				{alu_cy_l_w,alu_o_l		} =i_alu_in0[3:0] 	+alu_in1[3:0] +alu_in_cy;
				{alu_cy_c6_w,alu_o_c6	} =i_alu_in0[6:4] 	+alu_in1[6:4] +alu_cy_l_w;
				{o_cy,alu_o_c7			} =i_alu_in0[7] 	+alu_in1[7] +alu_cy_c6_w;
				o_alu_out	={alu_o_c7,alu_o_c6,alu_o_l};
				o_ac	=alu_cy_l_w;
				o_ov	=o_cy	^ alu_cy_c6_w;
				o_zo	=(o_alu_out == 8'b0);
			end
			else if (i_alu_mode ==	RL)
				o_alu_out	={i_alu_in0[6:0],i_alu_in0[7]};
			else if (i_alu_mode ==	RR)
				o_alu_out	={i_alu_in0[0],i_alu_in0[7:1]};
			else if (i_alu_mode ==	CPL)
				o_alu_out	=~i_alu_in0;
			else if (i_alu_mode ==	SWAP)
				o_alu_out	={i_alu_in0[3:0],i_alu_in0[7:4]};
			else if (i_alu_mode ==	SUMC)
				o_alu_out	=i_alu_in0 +alu_in1 +cy_q;
			else if (i_alu_mode ==	RLC)
				o_alu_out	={i_alu_in0[6:0],cy_q};
			else if	(i_alu_mode ==	RRC)
				o_alu_out	={cy_q,i_alu_in0[7:1]};
			else
				o_alu_out = 8'b00;
	end	else begin
			o_alu_out = 8'b00;
			
			o_cy 	= 1'b0;
			o_ov 	= 1'b0;
			o_ac 	= 1'b0;
			o_zo	= 1'b0;
	end
							//Logic operation circuit
wire	c_bit			=	i_alu_in0[	i_bit_sel[2:0]	];

wire	set_or_clr_temp	=	(bit_mode_sel == 3'b000) ? 	i_bit_set_or_clr:
							(bit_mode_sel == 3'b001) ?	~c_bit:
							
							(bit_mode_sel == 3'b010) ?	c_bit & i_alu_in1[7]:
							(bit_mode_sel == 3'b011) ?	c_bit | i_alu_in1[7]:
							
							(bit_mode_sel == 3'b100) ?	i_alu_in0[i_bit_sel - 4'd4]:
							
							(bit_mode_sel == 3'b101) ?	i_alu_in1[7]:
							//i_alu_in1[7]	-->	cy_q
							1'b0;

always @(*)
	begin
							/*
								{i_cy_set,i_ac,i_fg_set,
				
								sx_0_q[3:2],i_ov_set,1'b0,i_pr_set};
							*/
		cy_set		=i_alu_in0[7];
		ac_set		=i_alu_in0[6];
		ov_set		=i_alu_in0[2];
		zo_set		=i_alu_in0[1];
		pr_set		=i_alu_in0[0];
		case(i_bit_sel)
			4'h7:	o_cy_set	=	set_or_clr_temp;
			4'h1:	o_zo_set	=	set_or_clr_temp;
			4'h3:	o_ov_set	=	set_or_clr_temp;
			4'h0:	o_pr_set	=	set_or_clr_temp;
			4'h6:	o_ac_set	=	set_or_clr_temp;
			4'h5:	o_fg_set	=	set_or_clr_temp;
			default:begin end
		endcase
	
	end
	
/*
always @(*)
	begin
		sx_d	=sx_q;
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
				sx_d	=sx_q;
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
							sx_d[bit_sel - 4'd4]	=	set_or_clr_temp;
							c_bit	=	sx_q[bit_sel - 4'd4];
						end
					
					default:
						begin
						end
				endcase
			end
	end
*/
endmodule