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
`define                 ROM_RDY_LAG                 8'd63
// `define                 MANUAL_ROM_DBG              1'b1


module mc51_tb();
reg		sys_clk		=1'b0;
reg		sys_rst_n	=1'b1;

							//Clock generator
always #1	sys_clk	<=	~sys_clk;
							//External BUS
wire					we_n;
wire                    rd_n;
wire                    psen_n;   

//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
reg                     rom_ready       =1'b1; 
reg     [7:0]           rom_mem_rdata;
reg                     rom_sel;

wire                    intc_ready;
wire    [7:0]           intc_mem_rdata;
reg                     intc_sel;


reg     [7:0]           mem_rdata;
reg                     mem_ready;
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
wire    [7:0]           mem_wdata;
wire    [15:0]          mem_addr;
wire                    int_ack_n;
wire                    int_reti;
wire                    mem_sfr_n;   
wire                    int_req_n;
wire    [7:0]           int_so_num;
wire    [7:0]           int_resp_n;

wire                    exram_sel;
assign                  exram_sel  =   psen_n & mem_sfr_n ;
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
    .mem_data_rdy                       (mem_ready          ),
    .mem_rdata                          (mem_rdata          ),
	.mem_wdata                          (mem_wdata          ),
	.mem_addr                           (mem_addr           ),

    .mem_sfr_n                          (mem_sfr_n          ),
	
	.int_req_n                          (int_req_n          ),
	.int_ack_n                          (int_ack_n          ),
	.int_so_num                         (int_so_num         ),
	.int_reti                           (int_reti           )
);

nvi_intc        nvi_intc_inst(
    .clk                                (sys_clk            ),
    .reset_n                            (sys_rst_n          ),

//Naive-Memory Interface
    .mem_sel                            (intc_sel           ),
    .mem_addr                           (mem_addr           ),
    .mem_we_n                           (we_n               ),
    .mem_rd_n                           (rd_n               ),
    .mem_sfr_n                          (mem_sfr_n          ),
    .mem_wdata                          (mem_wdata          ),

    .mem_rdata                          (intc_mem_rdata     ),
    .mem_ready_out                      (intc_ready         ),

    .int_ack_n                          (int_ack_n          ),
    .int_reti                           (int_reti           ),

    .int_req_n                          (int_req_n          ),
    .int_so_num                         (int_so_num         ),


//Interrupt Signal Interface

    .int_exIO0                          (1'b0               ),
    .int_exIO1                          (1'b0               ),
    .int_TF0                            (1'b0               ),
    .int_TF1                            (1'b0               ),
    .int_UART0                          (1'b0               ),

    .int_resp_n                         (int_resp_n         )
);
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
                            //Simple NVI Master Mux
always @(*) begin
    intc_sel    =   ~mem_sfr_n  &   (mem_addr[15:5] ==  11'b0000_0000_101   );
    rom_sel     =   mem_sfr_n   &   (mem_addr[15:12] ==  4'h0               );
end
always @(*) begin
    mem_ready   =   (rom_sel    ==  1'b1    )   ?   rom_ready:
                    (intc_sel   ==  1'b1    )   ?   intc_ready:
                    (exram_sel  ==  1'b1    )   ?   1'b1:
                    1'b0;
end
always @(*) begin
    mem_rdata   =   (rom_sel    ==  1'b1    )   ?   rom_mem_rdata:
                    (intc_sel   ==  1'b1    )   ?   intc_mem_rdata:
                    8'bzzzz_zzzz;
end

//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
                            //DBG interface and message ouptut

always @(posedge (exram_sel & ~we_n))
    $display("%m at time: %t EXRAM Write Operation, Addr: %h -->  Data: %h",$time,mem_addr,mem_wdata);

//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
							//Prg_Rom Simulation Module 
`ifdef                  MANUAL_ROM_DBG
    always @(*) begin
            case(mem_addr)
                16'h0000:
                    rom_mem_rdata 			=`NOP;
                            //You can write down your simple test code here ... ...
                default:
                    rom_mem_rdata	        =`NOP;
            endcase
    end
`else
							//Load the prg_rom from the file
    parameter       ROM_SIZE    =  65536;
    reg    [7:0]    PRG_ROM     [ROM_SIZE-1:0];

    initial begin
        $readmemh("prg_rom.hex", PRG_ROM);
    end
    always @(*) begin
        rom_mem_rdata           = PRG_ROM[mem_addr];
    end
`endif

`ifdef                  ROM_RDY_LAG
    reg	[7:0]	do_cnt  =8'h00;
    reg	[15:0]	mem_addr_reg	=16'h0000;
    always @(posedge sys_clk)
        if(~psen_n)
            mem_addr_reg	<=	mem_addr;

    always @(posedge sys_clk) begin
        if(~psen_n && rom_ready)
            rom_ready           <=  1'b0;
        else if(rom_ready ==1'b0) begin
            do_cnt          <=  (do_cnt == `ROM_RDY_LAG) ? 8'd0:do_cnt +1;
            if(do_cnt == `ROM_RDY_LAG)
                rom_ready       <=  1'b1;
        end
    end
`else
    always @(*)
        rom_ready   =   1'b1;
`endif

initial begin
	#0		sys_rst_n	<=1'b1;
	#4		sys_rst_n	<=1'b0;
	#4		sys_rst_n	<=1'b1;

end
/*
    initial begin
        #0      int_req_n   <=1'b1;
        #8000   int_req_n   <=1'b0;
        wait(~int_ack_n);
        #0      int_req_n   <=1'b1;

    end
*/
endmodule