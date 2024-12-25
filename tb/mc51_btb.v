//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
//	FILE: 		mc51_btb.v
// 	AUTHOR:		Biggest_apple
// 	
//	ABSTRACT:	This's a mcs-51 ip core
// 	KEYWORDS:	fpga, basic module,signal process
// 
// 	MODIFICATION HISTORY:
//	$Log$
//			Biggest_apple				2024.4.1		Create the file
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
`timescale 				1ns/1ps
`include				"global_param.v"
module mc51_tb();
reg		sys_clk		=1'b0;
reg		sys_rst_n	=1'b1;

							//Clock generator
always #1	sys_clk	<=	~sys_clk;
							//External BUS
wire					we_n;
wire                    rd_n;
wire                    psen_n;   
reg                     ready_in    =1'b1; 
reg     [7:0]           mem_rdata;
wire    [7:0]           mem_wdata;
wire    [15:0]          mem_addr;
wire                    int_ack_n;  
wire                    int_reti;   
/*
mcs_51          mcs_51_inst(
	.clk								(sys_clk            ),
	.sys_rst_n							(sys_rst_n          ),
	
	.mem_addr		                    (mem_addr           ),
	.mem_rdata		                    (mem_rdata          ),
	//.mem_wdata		                (mem_wdata          ),
	
	//.we_n			                    (we_n               ),
	//.rd_n			                    (rd_n               ),
	.psen_n			                    (psen_n             ),
	
	.int_n_0		                    (int_n_0            ),
	.int_n_1		                    (int_n_1            ),
	
	.tx				                    (tx                 ),
	.rx				                    (rx                 ),
	.p1				                    (p1                 ),
	.p2				                    (p2                 ),
	
	.ready_in		                    (ready_in           )
);
*/
mc8051_top      mc8051_top_inst(
    .clk                                (sys_clk            ),
    .reset_n                            (sys_rst_n          ),

    .mem_we_n                           (we_n               ),
    .mem_rd_n                           (rd_n               ),
    .mem_psen_n                         (psen_n             ),
    .mem_data_rdy                       (ready_in           ),
    .mem_rdata                          (mem_rdata          ),
	.mem_wdata                          (mem_wdata          ),
	.mem_addr                           (mem_addr           ),
	
	.int_req_n                          (1'b1               ),
	.int_ack_n                          (int_ack_n          ),
	.int_so_num                         (8'h00              ),
	.int_reti                           (int_reti           )
);

							//Prg_Rom Simulation Module
always @(*) begin
		case(mem_addr)
			16'h0000:
				mem_rdata	        =`NOP;
			16'h0001:
				mem_rdata	        =`NOP;
            16'h0002:
                mem_rdata           =`MOV_A_IMM;
            16'h0003:
                mem_rdata           =8'h03;
/*
                16'h0004:
                    mem_rdata           =`MOV_A_DIR;
                16'h0005:
                    mem_rdata           =`ACC;
                16'h0006:
    //              mem_rdata           =`MOV_A_RN;
                    mem_rdata           =8'b1110_1010;
                16'h0007:
    //              mem_rdata           =`MOV_A_F_RN;
                    mem_rdata           =8'b1110_0111;
                16'h0008:
    //              mem_rdata           =`MOV_RN_A;
                    mem_rdata           =8'b1111_1_100;
                16'h0009:
    //              mem_rdata           =`MOV_RN_DIR;
                    mem_rdata           =8'b1010_1_111;
                16'h000a:
                    mem_rdata           =8'h00;
                16'h000b:
    //              mem_rdata           =`MOV_RN_IMM;
                    mem_rdata           =8'b0111_1_110;
                16'h000c:
                    mem_rdata           =8'hff;
                16'h000d:
                    mem_rdata           =`MOV_DIR_A;
                16'h000e:
                    mem_rdata           =8'h10;
                16'h000f:
    //              mem_rdata           =`MOV_DIR_RN;
                    mem_rdata           =8'b1000_1000;
                16'h0010:
                    mem_rdata           =8'h11;
                16'h0011:
                    mem_rdata           =`MOV_DIR1_DIR2;
                16'h0012:
                    mem_rdata           =8'h1f;
                16'h0013:
                    mem_rdata           =8'h20;
*/     
            16'h0004:
                mem_rdata           =`ADD_A_IMM;
            16'h0005:
                mem_rdata           =8'hff;
            16'h0006:
                mem_rdata           =`ADDC_A_IMM;
            16'h0007:
                mem_rdata           =8'h00;
            16'h0008:
                mem_rdata           =`MOV_DIR_A;
            16'h0009:
                mem_rdata           =8'hf0;
            16'h000a:
                mem_rdata           =`MOV_A_IMM;
            16'h000b:
                mem_rdata           =8'h44;
            16'h000c:
                mem_rdata           =`DIV_AB;
            16'h000d:
                mem_rdata           =`MUL_AB;
            16'h000e:
                mem_rdata           =`MOV_DIR_IMM;
            16'h000f:
                mem_rdata           =`B;
            16'h0010:
                mem_rdata           =8'h12;
            16'h0011:
                mem_rdata           =`MOV_DIR_IMM;
            16'h0012:
                mem_rdata           =`SP;
            16'h0013:
                mem_rdata           =8'h20;
            16'h0014:
                mem_rdata           =`DEC_A;
            16'h0015:
                mem_rdata           =`RRC_A;
            16'h0016:
                mem_rdata           =`RRC_A;
            16'h0017:
                mem_rdata           =`RRC_A;
            16'h0018:
                mem_rdata           =`SETB_C;
            16'h0019:
                mem_rdata           =`SETB_BIT;
            16'h001a:
                mem_rdata           =8'h21;
			default:
				mem_rdata	        =`NOP;
		
		endcase
end
reg	[7:0]	do_cnt  =8'h00;
reg	[15:0]	mem_addr_reg	=16'h0000;
always @(posedge sys_clk)
	if(~psen_n)
		mem_addr_reg	<=	mem_addr;

always @(posedge sys_clk) begin
    if(~psen_n && ready_in)
        ready_in        <=  1'b0;
    else if(ready_in ==1'b0) begin
        do_cnt          <=  (do_cnt == 8'd63) ? 8'd0:do_cnt +1;
        if(do_cnt == 8'd63)
            ready_in    <=  1'b1;
    end
end
initial begin
	#0		sys_rst_n	<=1'b1;
	#4		sys_rst_n	<=1'b0;
	#4		sys_rst_n	<=1'b1;

end

endmodule