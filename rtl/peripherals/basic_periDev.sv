//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
//	FILE: 		basic_periDev.v
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
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
/*
`define             ENABLE_ENHANCE_IO
*/
`define             DISABLE_ENHANCE_IO
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
module nvi_periDev(
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
//Interrupt REQ PORT
    input       [7:0]           int_resp_n,

    output                      int_exIO0,
    output                      int_exIO1,
    output                      int_TF0,
    output                      int_TF1,
    output                      int_UART0,

//IO Port & USART PORT
    inout       [7:0]           io_p0,
    inout       [7:0]           io_p1,
    inout       [7:0]           io_p2,
    inout       [7:0]           io_p3,

    input                       us_rx,
    output                      us_tx

);

reg     [7:0]       TCON_q;
reg     [7:0]       TCON_d;
reg     [7:0]       TMOD_q;
reg     [7:0]       TMOD_d;

reg     [7:0]       SCON_q;
reg     [7:0]       SCON_d;
reg     [7:0]       SBUF_q;
reg     [7:0]       SBUF_d;

reg     [7:0]       PCON_q;
reg     [7:0]       PCON_d;
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
reg     [3:0]       clk_div12_cnt;
always_ff @(posedge clk or negedge reset_n) begin : CLK_DIV12_GENERATOR
    if(~reset_n)    clk_div12_cnt   <=  'd1;
    else            clk_div12_cnt   <=  (clk_div12_cnt  ==  'd12)   ?   'd1 :   clk_div12_cnt + 1;
end
wire                clk_div12   =   (clk_div12_cnt  ==  'd6);
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
reg     [1:0]       t0_extIN_saFF;
always_ff @(posedge clk or negedge reset_n) begin : T0_EXTIN_SA_FlipFlop
    if(~reset_n)    t0_extIN_saFF   <=  2'b00;
    else            t0_extIN_saFF   <=  (clk_div12  ==  1'b1)   ?   {t0_extIN_saFF[0],io_p3[4]} :   t0_extIN_saFF;
end
wire                t0_extIN_neg    =   (t0_extIN_saFF  ==  2'b10);
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
reg     [1:0]       t1_extIN_saFF;
always_ff @(posedge clk or negedge reset_n) begin : T1_EXTIN_SA_FlipFlop
    if(~reset_n)    t1_extIN_saFF   <=  2'b00;
    else            t1_extIN_saFF   <=  (clk_div12  ==  1'b1)   ?   {t1_extIN_saFF[0],io_p3[5]} :   t1_extIN_saFF;
end
wire                t1_extIN_neg    =   (t1_extIN_saFF  ==  2'b10);
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
reg                 w_GATE;
reg                 w_CT;

reg                 t0_refPulse;
reg                 t1_refPulse;

always_comb begin : TIMER_RefPulse_SOURCE
    if(w_CT  ==  1'b0) begin
							//  C/NT:0    imer0/1 pulse source comes from internal frequency divider
        t0_refPulse     =   ((~w_GATE)  |  io_p3[2])    ?   clk_div12       :   1'b0;
        t1_refPulse     =   ((~w_GATE)  |  io_p3[3])    ?   clk_div12       :   1'b0;
    end else begin
							//  C/NT:1    imer0/1 pulse source comes from external io(p3.4 & p3.5)
        t0_refPulse     =   ((~w_GATE)  |  io_p3[2])    ?   t0_extIN_neg    :   1'b0;
        t1_refPulse     =   ((~w_GATE)  |  io_p3[3])    ?   t1_extIN_neg    :   1'b0;
    end
end
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
reg     [7:0]       TH0_q,TH0_d;
reg     [7:0]       TL0_q,TL0_d;
reg     [7:0]       TH1_q,TH1_d;
reg     [7:0]       TL1_q,TL1_d;

reg     [7:0]       TH0_d0,TL0_d0;
reg     [7:0]       TH1_d0,TL1_d0;

reg                 w_TR0;
reg                 w_TR1;
reg     [1:0]       w_MOD;

reg                 TF0_d0;
reg                 TF0_q;

reg                 TF1_d0;
reg                 TF1_q;
                            //  TF1_d1 is used for baud rate generation
reg                 TF1_d1;

wire    [15:0]      T0_16B  =   {TH0_q,     TL0_q};
wire    [15:0]      T1_16B  =   {TH1_q,     TL1_q};

always_ff @(posedge clk or negedge reset_n) begin : TIMER_FFLOGIC
    if(~reset_n) begin
        {TH0_q,     TL0_q}  <=  16'h00_00;
        {TH1_q,     TL1_q}  <=  16'h00_00;
    end else begin
        {TH0_q,     TL0_q}  <=  {TH0_d,     TL0_d};
        {TH1_q,     TL1_q}  <=  {TH1_d,     TL1_d};
    end
end
always_comb begin : TIMER0_COLOGIC
    TH0_d0              =   TH0_q;
    TL0_d0              =   TL0_q;
    TF0_d0              =   TF0_q;

    TH1_d0              =   TH1_q;
    TL1_d0              =   TL1_q;
    TF1_d0              =   TF1_q;

    TF1_d1              =   1'b0;

                            // Classify different working modes
    case(w_MOD)
        2'b00:  
            begin
                {TH0_d,     TL0_d}      =   (T0_16B[13] ==  1'b1    &&  w_TR0)   ?   'b0     :   T0_16B +1;
                {TH1_d,     TL1_d}      =   (T1_16B[13] ==  1'b1    &&  w_TR1)   ?   'b0     :   T1_16B +1;

                TF1_d0                  =   (T1_16B[13] ==  1'b1)   ?   1'b1    :   TF1_q;
                TF0_d0                  =   (T0_16B[13] ==  1'b1)   ?   1'b1    :   TF0_q;
            end
        2'b01:
            begin
                {TH0_d,     TL0_d}      =   (&  T0_16B ==  1'b1    &&  w_TR0)   ?   'b0     :   T0_16B +1;
                {TH1_d,     TL1_d}      =   (&  T1_16B ==  1'b1    &&  w_TR1)   ?   'b0     :   T1_16B +1;

                TF1_d0                  =   (&  T1_16B ==  1'b1)    ?   1'b1    :   TF1_q;
                TF0_d0                  =   (&  T0_16B ==  1'b1)    ?   1'b1    :   TF0_q;
            end
        2'b10:
            begin
                            // AutoReload mode
                TL0_d                   =   (&  TL0_q ==  1'b1    &&  w_TR0)    ?   TH0_q   :   TL0_q +1;
                TL1_d                   =   (&  TL1_q ==  1'b1    &&  w_TR1)    ?   TH1_q   :   TL1_q +1;

                TF1_d0                  =   (&  TL1_q ==  1'b1)     ?   1'b1    :   TF1_q;
                TF0_d0                  =   (&  TL0_q ==  1'b1)     ?   1'b1    :   TF0_q;
            end
        2'b11:
            begin
                TL0_d                   =   (&  TL0_q ==  1'b1    &&  w_TR0)    ?   'b0     :   TL0_q +1;
                TH0_d                   =   (&  TH0_q ==  1'b1    &&  w_TR1)    ?   'b0     :   TH0_q +1;

                TF1_d0                  =   (&  TH0_q ==  1'b1)     ?   1'b1    :   TF1_q;
                TF0_d0                  =   (&  TL0_q ==  1'b1)     ?   1'b1    :   TF0_q;

                TL1_d                   =   (&  TL1_q ==  1'b1)     ?   TH1_q   :   TL1_q +1;
                TF1_d1                  =   (&  TL1_q ==  1'b1) ;
            end
        default:    begin       end
    endcase
end
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
reg                 w_SMOD;
reg                 uart_baudRate_pulse;

//-----------------------------------------------------------------------------------------------------------------------------------------------------------//


//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
endmodule