//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
//	FILE: 		basic_intc.sv
// 	AUTHOR:		Biggest_apple
// 	
//	ABSTRACT:	
// 	KEYWORDS:	fpga, basic module,signal process
// 
// 	MODIFICATION HISTORY:
//	$Log$
//			Biggest_apple				2024.12.20		Create the file
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
`timescale 				1ns/1ps
`include				"global_param.v"
module nvi_intc(
	input					    clk,
	input					    reset_n,

//Naive-Memory Interface
    input                       mem_sel,
    input       [15:0]          mem_addr,
    input                       mem_we_n,
    input                       mem_rd_n,
    input                       mem_sfr_n,
    input       [7:0]           mem_wdata,

    output reg  [7:0]           mem_rdata,
    output                      mem_ready_out,

    input                       int_ack_n,
    input                       int_reti,

    output reg                  int_req_n,
    output reg  [7:0]           int_so_num,

//Interrupt Signal Interface

    input                       int_exIO0,
    input                       int_exIO1,
    input                       int_TF0,
    input                       int_TF1,
    input                       int_UART0
);

reg     [7:0]       IE_q;
reg     [7:0]       IE_d;
reg     [7:0]       IP_q;
reg     [7:0]       IP_d;

wire                w_EA    =   IE_q[7];
wire                w_ES    =   IE_q[4];
wire                w_ET1   =   IE_q[3];
wire                w_EX1   =   IE_q[2];
wire                w_ET0   =   IE_q[1];
wire                w_EX0   =   IE_q[0];

reg                 int_exIO0_q;
reg                 int_exIO1_q;
reg                 int_TF0_q;
reg                 int_TF1_q;
reg                 int_UART0_q;
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
always @(posedge clk or negedge reset_n)
    if(~reset_n)
        int_exIO0_q     <=  1'b0;
    else
        int_exIO0_q     <=  int_exIO0   & w_EX0 &   w_EA;
always @(posedge clk or negedge reset_n)
    if(~reset_n)
        int_exIO1_q     <=  1'b0;
    else
        int_exIO1_q     <=  int_exIO1   & w_EX1 &   w_EA;
always @(posedge clk or negedge reset_n)
    if(~reset_n)
        int_TF0_q       <=  1'b0;
    else
        int_TF0_q       <=  int_TF0     & w_ET0 &   w_EA;
always @(posedge clk or negedge reset_n)
    if(~reset_n)
        int_TF1_q       <=  1'b0;
    else
        int_TF1_q       <=  int_TF1     & w_ET1 &   w_EA;
always @(posedge clk or negedge reset_n)
    if(~reset_n)
        int_UART0_q     <=  1'b0;
    else
        int_UART0_q     <=  int_UART0   & w_ES  &   w_EA;
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
reg     [7:0]       int_Hprio_req;
reg     [7:0]       int_Lprio_req;
wire    [7:0]       int_req_wline       =   {3'b0,int_UART0_q,int_TF1_q,int_exIO1_q,int_TF0_q,int_exIO0_q};
always_comb begin : IntReq_PriorityMux
        int_Hprio_req   =   IP_q & int_req_wline;
        int_Lprio_req   =   int_Hprio_req ^ int_req_wline;
end
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
`define             EA_ENABLE_CLRPEND
/*
`define             EA_DISABLE_CLRPEND
*/
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
reg                 int_Lprio_PendClr;
reg                 int_Hprio_PendClr;

reg     [7:0]       int_Lprio_PendFF;
reg     [7:0]       int_Hprio_PendFF;

always_ff @(posedge clk or negedge reset_n) 
    begin : IntReq_PendingLatch
        if(~reset_n) begin
            int_Lprio_PendFF    <=  8'h00;
            int_Hprio_PendFF    <=  8'h00;
    end 
`ifdef  EA_ENABLE_CLRPEND
    else if (~w_EA      ) begin
            int_Lprio_PendFF    <=  8'h00;
            int_Hprio_PendFF    <=  8'h00;
    end 
`endif
    else if(int_Hprio_PendClr | int_Lprio_PendClr) begin
            if(int_Hprio_PendClr)
                case(int_so_num)
                    `INT_VECTOR_0   :   int_Hprio_PendFF[0] <=  1'b0;
                    `INT_VECTOR_1   :   int_Hprio_PendFF[1] <=  1'b0;
                    `INT_VECTOR_2   :   int_Hprio_PendFF[2] <=  1'b0;
                    `INT_VECTOR_3   :   int_Hprio_PendFF[3] <=  1'b0;
                    `INT_VECTOR_4   :   int_Hprio_PendFF[4] <=  1'b0;
                    default:    begin   end
                endcase
            else
                case(int_so_num)
                    `INT_VECTOR_0   :   int_Lprio_PendFF[0] <=  1'b0;
                    `INT_VECTOR_1   :   int_Lprio_PendFF[1] <=  1'b0;
                    `INT_VECTOR_2   :   int_Lprio_PendFF[2] <=  1'b0;
                    `INT_VECTOR_3   :   int_Lprio_PendFF[3] <=  1'b0;
                    `INT_VECTOR_4   :   int_Lprio_PendFF[4] <=  1'b0;
                    default:    begin   end
                endcase

        end else begin
            int_Lprio_PendFF    <=  int_Lprio_PendFF    |   int_Lprio_req;
            int_Hprio_PendFF    <=  int_Hprio_PendFF    |   int_Hprio_req;
        end
    end
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
localparam          W_INT_SWF   =   3'h0;
localparam          W_LPRI_LOOP =   3'h1;
localparam          W_HPRI_LOOP =   3'h2;
localparam          W_LPRI_HOLD =   3'h3;
localparam          W_HPRI_HOLD =   3'h4;

reg     [2:0]       wstate;
always_ff @(posedge clk or negedge reset_n) 
    begin : INTC_MainFSM
        if(~reset_n) begin
            wstate              <=  W_INT_SWF;
            int_req_n           <=  1'b1;

//          int_Hprio_PendClr   <=  1'b0;
//          int_Lprio_PendClr   <=  1'b0;
        end else
            case (wstate)
                W_INT_SWF:
                    if(|int_Hprio_PendFF)
                        wstate          <=  W_HPRI_LOOP;
                    else if(|int_Lprio_PendFF)
                        wstate          <=  W_LPRI_LOOP;
                    else
                        wstate          <=  W_INT_SWF;
                W_LPRI_LOOP:
                    begin
                        int_req_n       <=  1'b0;
                        if(~int_ack_n) begin
                            wstate      <=  W_LPRI_HOLD;
                            int_req_n   <=  1'b1;
                        end
                    end
                W_HPRI_LOOP:
                    begin
                        int_req_n       <=  1'b0;
                        if(~int_ack_n) begin
                            wstate      <=  W_HPRI_HOLD;
                            int_req_n   <=  1'b1;
                        end
                    end
                W_LPRI_HOLD,W_HPRI_HOLD:
                    if(int_reti)
                            wstate      <=  W_INT_SWF;
                default:    wstate      <=  3'bzzz;
            endcase
    end
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
/*
    reg                 int_reti_q0 =   1'b0;
    reg                 int_reti_q1 =   1'b0;
    wire                int_reti_pEdge;
    always @(posedge clk)
        {int_reti_q1,   int_reti_q0     }   <=  {int_reti_q0,   int_reti    };
    assign              int_reti_pEdge      =   {int_reti_q1,int_reti_q0}   ==  2'b01;
*/
always_comb begin
        int_Hprio_PendClr   =   (wstate ==  W_HPRI_HOLD)    &   int_reti;
        int_Lprio_PendClr   =   (wstate ==  W_LPRI_HOLD)    &   int_reti;
end
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
always_comb begin : INtVectorEntry_Gen
    if(wstate   ==  W_HPRI_LOOP ||  wstate  ==  W_HPRI_HOLD)
        int_so_num  =   (int_Hprio_PendFF[0])   ?   `INT_VECTOR_0:
                        (int_Hprio_PendFF[1])   ?   `INT_VECTOR_1:
                        (int_Hprio_PendFF[2])   ?   `INT_VECTOR_2:
                        (int_Hprio_PendFF[3])   ?   `INT_VECTOR_3:
                        (int_Hprio_PendFF[4])   ?   `INT_VECTOR_4:  

                        8'h00;
    else if(wstate   ==  W_LPRI_LOOP ||  wstate  ==  W_LPRI_HOLD)
        int_so_num  =   (int_Lprio_PendFF[0])   ?   `INT_VECTOR_0:
                        (int_Lprio_PendFF[1])   ?   `INT_VECTOR_1:
                        (int_Lprio_PendFF[2])   ?   `INT_VECTOR_2:
                        (int_Lprio_PendFF[3])   ?   `INT_VECTOR_3:
                        (int_Lprio_PendFF[4])   ?   `INT_VECTOR_4:  

                        8'h00;
    else
        int_so_num  =   8'h00;
end
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
wire                intc_config_active;
assign              intc_config_active  =   ~mem_sfr_n  &&  mem_sel;
always_ff @(posedge clk or negedge reset_n)
    if(~reset_n) begin
        IE_q        <=      8'h00;
        IP_q        <=      8'h00;
    end else begin
        IE_q        <=      IE_d;
        IP_q        <=      IP_d;
    end

always_comb begin
    IE_d            =       IE_q;
    IP_d            =       IP_q;

    if(~mem_we_n    &&  intc_config_active)
        case(mem_addr[7:0])
            `IE     :       IE_d    =   mem_wdata;
            `IP     :       IP_d    =   mem_wdata;
            default :       begin   end
        endcase
end

always_comb begin
    if(~mem_rd_n    &&  intc_config_active)
        case(mem_addr[7:0])
            `IE     :       mem_rdata   =   IE_q;
            `IP     :       mem_rdata   =   IP_q;
            default :       mem_rdata   =   8'bzzzz_zzzz;
        endcase
    else
        mem_rdata   =   8'bzzzz_zzzz;
end
assign              mem_ready_out       =   1'b1;
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
endmodule