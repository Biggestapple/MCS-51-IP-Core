//----------------------------------------------------------------------------------------------------------
//	FILE: 		mc51_btb.v
// 	AUTHOR:		Biggest_apple
// 	
//	ABSTRACT:	This's a mcs-51 ip core
// 	KEYWORDS:	fpga, basic module,signal process
// 
// 	MODIFICATION HISTORY:
//	$Log$
//			Biggest_apple 		2024.1.1
//-----------------------------------------------------------------------------------------------------------
module mc51_tb();
reg		sys_clk		=1'b0;
reg		sys_rst_n	=1'b1;

							//Clock generator
always #1	sys_clk	<=	~sys_clk;
							//External BUS
wire	[15:0]		mem_addr;
wire				we_n;
wire				rd_n;
wire				psen_n;
reg		ready_in	=1'b1;
wire	[7:0]		p1;
wire	[7:0]		p2;
wire	tx;
reg		rx			=1'b0;
reg		int_n_0,int_n_1;
wire	[7:0]		mem_wdata;
reg		[7:0]		mem_rdata	=	8'h00;



mcs_51 mcs_51_inst(
	.clk			(sys_clk),
	.sys_rst_n		(sys_rst_n),
	
	.mem_addr		(mem_addr),
	.mem_rdata		(mem_rdata),
	.mem_wdata		(mem_wdata),
	
	.we_n			(we_n),
	.rd_n			(rd_n),
	.psen_n			(psen_n),
	
	.int_n_0		(int_n_0),
	.int_n_1		(int_n_1),
	
	.tx				(tx),
	.rx				(rx),
	.p1				(p1),
	.p2				(p2),
	
	.ready_in		(ready_in)
	
);
initial begin
	#0		sys_rst_n	<=1'b1;int_n_0	<=1'b1;int_n_1	<=1'b1;
	#4		sys_rst_n	<=1'b0;
	#4		sys_rst_n	<=1'b1;

	#2000	$finish;

end
endmodule